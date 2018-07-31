--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: log2; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA log2;


SET search_path = log2, pg_catalog;


--
-- Name: log_execution(character varying, character varying, character varying, character varying, character varying, timestamp with time zone); Type: FUNCTION; Schema: log2; Owner: -
--

CREATE FUNCTION log_execution(pid character varying, graph_param character varying, mode_param character varying, status_param character varying, detailed_status_param character varying, time_param timestamp with time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE
  var_rowcount         INTEGER;
  var_schedule_id      INTEGER;
  var_execution_log_id INTEGER;
BEGIN

  IF status_param NOT IN ('STARTED', 'ERROR', 'OK', 'FINISHED', 'WARNING', 'RUNNING')
  THEN
    RAISE EXCEPTION 'MS ETL: the alowed status is:''ERROR'', ''START'' ''OK'', ''WARNING'', ''RUNNING'';';
    RETURN COALESCE($1, -1);
  END IF;

  --RAISE WARNING 'Params server pid(%)', pid;		
  --RAISE WARNING 'Params server graph_param(%)', graph_param;		
  --RAISE WARNING 'Params server mode_param(%)', mode_param;		
  --RAISE WARNING 'Params server status_param(%)', status_param;		

  SELECT
    id,
    count(id)
    OVER (PARTITION BY r_project)
  INTO var_schedule_id, var_rowcount
  FROM schedule
  WHERE is_deleted = FALSE
        AND r_project = pid
        AND graph_name = graph_param
        AND (((mode IS NULL OR mode = '') AND (mode_param IS NULL OR mode_param = '')) OR mode = mode_param);

  --RAISE WARNING 'Params server var_schedule_id(%)', var_schedule_id;		

  IF var_rowcount = 1 AND var_schedule_id IS NOT NULL
  THEN

    IF status_param = 'STARTED'
    THEN

      --RAISE WARNING 'Params server STARTED section(%)', 1;			

      UPDATE running_executions
      SET
        status          = 'RUNNING',
        detailed_status = detailed_status_param,
        event_start     = COALESCE(time_param, now()),
        event_end       = NULL
      WHERE schedule_id = var_schedule_id;

      IF NOT FOUND
      THEN
        INSERT INTO running_executions (schedule_id, status, detailed_status, event_start)
        VALUES (var_schedule_id, 'RUNNING', detailed_status_param, COALESCE(time_param, now()));
      END IF;

      -- UPDATE execution_log

      INSERT INTO execution_log (r_schedule, status, detailed_status, event_start)
      VALUES (var_schedule_id, 'RUNNING', detailed_status_param, COALESCE(time_param, now()))
      RETURNING id
        INTO var_execution_log_id;

      UPDATE execution_log
      SET
        status          = 'CANCELED',
        detailed_status = 'CANCELED by new execution id: ' || var_execution_log_id,
        event_end       = COALESCE(time_param, now())
      WHERE r_schedule = var_schedule_id
            AND status = 'RUNNING'
            AND id < var_execution_log_id;

      --RAISE WARNING 'Params server number of ROWS(%)', var_rowcount;			

    ELSEIF status_param IN ('ERROR', 'FINISHED', 'OK')
      THEN
        var_rowcount := 0;

        --RAISE WARNING 'Params server ERROR section(%)', 1;	

        UPDATE running_executions
        SET
          event_end       = COALESCE(time_param, now()),
          status          = status_param,
          detailed_status = detailed_status_param
        WHERE schedule_id = var_schedule_id;

        UPDATE execution_log l_main
        SET
          status          = status_param,
          detailed_status = detailed_status_param,
          event_end       = COALESCE(time_param, now())
        FROM execution_log l
        WHERE NOT EXISTS
        (
            SELECT l2.id
            FROM execution_log l2
            WHERE l2.r_schedule = l.r_schedule AND l2.status = 'RUNNING' AND l2.id > l.id
        )
              AND
              l.status = 'RUNNING'
              AND
              l_main.id = l.id
              AND
              l.r_schedule = var_schedule_id;

        GET DIAGNOSTICS var_rowcount = ROW_COUNT;

        --RAISE WARNING 'Params server number of ROWS(%)', var_rowcount;				

    END IF;
  ELSE
    --RAISE WARNING 'Error server section(%)', var_rowcount;				
    -- If the var_rowcount is 0, something went wrong and we need to log it
    INSERT INTO dump_log (project_pid, graph_name, mode, text) VALUES
      (pid, graph_param, mode_param,
       concat(status_param, ' D: ', detailed_status_param, ' @: ', CAST(time_param AS TEXT), ' RC: ', var_rowcount));

  END IF;
  RETURN var_rowcount;

END
$_$;


--
-- Name: log_execution_for_api(character varying, character varying, character varying, timestamp with time zone, character varying); Type: FUNCTION; Schema: log2; Owner: -
--

CREATE FUNCTION log_execution_for_api(param_gooddata_schedule_id character varying, status_param character varying, detailed_status_param character varying, time_param timestamp with time zone, request_id_param character varying) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE 
	rowcount INTEGER;
	param_schedule_id INTEGER;	
	param_number_of_consequent_errors INTEGER;
BEGIN

  IF status_param not in ('STARTED','ERROR','OK','FINISHED','WARNING','RUNNING') then
        RAISE EXCEPTION 'MS ETL: the alowed status is:''ERROR'', ''START'' ''OK'', ''WARNING'', ''RUNNING'';';
        RETURN COALESCE($1,-1);
  END IF;

  --RAISE WARNING 'Params pid(%)', pid;		
  --RAISE WARNING 'Params graph_param(%)', graph_param;		
  --RAISE WARNING 'Params mode_param(%)', mode_param;		
  --RAISE WARNING 'Params status_param(%)', status_param;		
  --RAISE WARNING 'Params param_schedule_id(%)', param_schedule_id;		

  SELECT s.id INTO param_schedule_id FROM log2.schedule s
  WHERE 
	s.gooddata_schedule = param_gooddata_schedule_id
		and
	s.is_deleted = false
  ORDER BY s.id DESC		
  LIMIT 1;	
  
  

  IF (status_param  = 'STARTED' AND param_schedule_id IS NOT NULL) THEN

	--RAISE WARNING 'Params STARTED section(%)', 1;			
	UPDATE log2.running_executions 
		SET 
		  event_start		=	COALESCE(time_param,now()), 
		  event_end  		= 	NULL,
		  status 		= 	'RUNNING',
		  detailed_status 	=	detailed_status_param,
		  request_id		=  	request_id_param	
		WHERE schedule_id=param_schedule_id;

	INSERT INTO log2.running_executions (schedule_id, event_start, status, detailed_status)
        SELECT param_schedule_id, COALESCE(time_param,now()), 'RUNNING',detailed_status_param
        WHERE NOT EXISTS (SELECT 1 FROM log2.running_executions WHERE schedule_id=param_schedule_id);


	INSERT INTO log2.execution_log (r_schedule,status,detailed_status,event_start,request_id)
	SELECT s.id,'RUNNING',detailed_status_param,COALESCE(time_param,now()),request_id_param
	FROM log2.schedule s 
	WHERE s.id = param_schedule_id;

        GET DIAGNOSTICS rowcount = ROW_COUNT; 	

        --RAISE WARNING 'Params number of ROWS(%)', rowcount;			

  ELSIF (((status_param = 'ERROR') OR (status_param = 'FINISHED') OR (status_param = 'OK')) AND param_schedule_id IS NOT NULL) THEN

	--RAISE WARNING 'Params ERROR section(%)', 1;	
	SELECT 
		CASE 
			WHEN status_param = 'ERROR' THEN r.number_of_consequent_errors + 1
			ELSE 0
		END
	INTO param_number_of_consequent_errors 
	FROM log2.running_executions r
	WHERE schedule_id=param_schedule_id;

	UPDATE log2.running_executions 
	SET 
	  event_end  		= 	COALESCE(time_param,now()),
	  status 		= 	status_param,
	  detailed_status 	=	detailed_status_param,  
	  number_of_consequent_errors = param_number_of_consequent_errors
	WHERE schedule_id=param_schedule_id and COALESCE(time_param,now()) > event_start;

	UPDATE log2.execution_log l_main
		SET 
			status = status_param,
			detailed_status = detailed_status_param,
			event_end = COALESCE(time_param,now())
	FROM log2.execution_log l
	INNER JOIN log2.schedule s ON l.r_schedule = s.id
	WHERE
		l.status = 'RUNNING' 
	AND 
		l_main.id = l.id 
	AND 
		l.request_id = request_id_param;
	

        GET DIAGNOSTICS rowcount = ROW_COUNT; 	

	--RAISE WARNING 'Params number of ROWS(%)', rowcount;			
	

  END IF;

  IF (rowcount = 0) THEN
	-- If the rowcount is 0, something went wrong and we need to log it
	--RAISE WARNING 'Error section(%)', rowcount;				
	INSERT INTO log2.dump_log (schedule_id,text) VALUES (param_schedule_id,status_param || ' ' || detailed_status_param || ' ' ||  CAST(time_param as text) || request_id_param  );
  END IF;

  RETURN rowcount;	


  
END;
$_$;


--
-- Name: log_execution_for_splunk(character varying, character varying, character varying, character varying, character varying, character varying, character varying, timestamp with time zone); Type: FUNCTION; Schema: log2; Owner: -
--

CREATE FUNCTION log_execution_for_splunk(pid character varying, schedule_id_param character varying, request_id_param character varying, graph_param character varying, mode_param character varying, status_param character varying, detailed_status_param character varying, time_param timestamp with time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE
  rowcount                        INTEGER;
  var_schedule_id                 INTEGER;
  var_number_of_consequent_errors INTEGER;
BEGIN

  IF status_param NOT IN ('STARTED', 'ERROR', 'OK', 'FINISHED', 'WARNING', 'RUNNING', 'CANCELED')
  THEN
    RAISE EXCEPTION 'MS ETL: the alowed status is:''ERROR'', ''START'' ''OK'', ''WARNING'', ''RUNNING'';';
    RETURN COALESCE($1, -1);
  END IF;

  --RAISE WARNING 'Params pid(%)', pid;   
  --RAISE WARNING 'Params graph_param(%)', graph_param;   
  --RAISE WARNING 'Params mode_param(%)', mode_param;   
  --RAISE WARNING 'Params status_param(%)', status_param;   

  SELECT s.id
  INTO var_schedule_id
  FROM schedule s
  WHERE
    s.is_deleted = FALSE
    AND
    s.r_project = pid
    AND
    s.gooddata_schedule = schedule_id_param
  LIMIT 1;

  --RAISE WARNING 'Params var_schedule_id(%)', var_schedule_id;
  IF var_schedule_id IS NOT NULL
  THEN
    rowcount := 0;
    IF status_param = 'STARTED'
    THEN

      --RAISE WARNING 'Params STARTED section(%)', 1;

      UPDATE running_executions
      SET
        event_start     = COALESCE(time_param, now()),
        event_end       = NULL,
        status          = 'RUNNING',
        detailed_status = detailed_status_param,
        request_id      = request_id_param
      WHERE schedule_id = var_schedule_id;

      INSERT INTO running_executions (schedule_id, event_start, status, detailed_status)
        SELECT
          var_schedule_id,
          COALESCE(time_param, now()),
          'RUNNING',
          detailed_status_param
        WHERE NOT EXISTS(SELECT 1
                         FROM running_executions
                         WHERE schedule_id = var_schedule_id);

      INSERT INTO execution_log (r_schedule, status, detailed_status, event_start, request_id)
        SELECT
          s.id,
          'RUNNING',
          detailed_status_param,
          COALESCE(time_param, now()),
          request_id_param
        FROM schedule s
        WHERE s.id = var_schedule_id;

      GET DIAGNOSTICS rowcount = ROW_COUNT;

      --RAISE WARNING 'Params number of ROWS(%)', rowcount;     

    ELSEIF status_param IN ('ERROR', 'FINISHED', 'OK')
      THEN

        --RAISE WARNING 'Params ERROR section(%)', 1; 

        SELECT CASE
               WHEN status_param = 'ERROR'
                 THEN r.number_of_consequent_errors + 1
               ELSE 0
               END
        INTO var_number_of_consequent_errors
        FROM running_executions r
        WHERE schedule_id = var_schedule_id;


        UPDATE running_executions
        SET
          event_end                   = COALESCE(time_param, now()),
          status                      = status_param,
          detailed_status             = detailed_status_param,
          number_of_consequent_errors = var_number_of_consequent_errors
        WHERE schedule_id = var_schedule_id AND COALESCE(time_param, now()) > event_start;

        UPDATE execution_log l_main
        SET
          status          = status_param,
          detailed_status = detailed_status_param,
          event_end       = COALESCE(time_param, now())
        FROM execution_log l
          INNER JOIN schedule s ON l.r_schedule = s.id
        WHERE
          l.status = 'RUNNING'
          AND
          l_main.id = l.id
          AND
          l.request_id = request_id_param;


        GET DIAGNOSTICS rowcount = ROW_COUNT;

        --RAISE WARNING 'Params number of ROWS(%)', rowcount;     


    END IF;
  END IF;

  IF rowcount = 0
  THEN
    -- If the rowcount is 0, something went wrong and we need to log it
    --RAISE WARNING 'Error section(%)', rowcount;       
    INSERT INTO dump_log (project_pid, schedule_id, graph_name, mode, text) VALUES
      (pid, schedule_id_param, graph_param, mode_param,
       status_param || ' ' || detailed_status_param || ' ' || CAST(time_param AS TEXT) || ' ' || request_id_param);
  END IF;

  RETURN rowcount;

END;
$_$;


--
-- Name: log_execution_for_splunk(character varying, character varying, character varying, character varying, character varying, character varying, character varying, timestamp with time zone, text); Type: FUNCTION; Schema: log2; Owner: -
--

CREATE FUNCTION log_execution_for_splunk(pid character varying, schedule_id_param character varying, request_id_param character varying, graph_param character varying, mode_param character varying, status_param character varying, detailed_status_param character varying, time_param timestamp with time zone, error_text_param text) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE
  rowcount                        INTEGER;
  var_schedule_id                 INTEGER;
  var_number_of_consequent_errors INTEGER;
BEGIN

  IF status_param NOT IN ('STARTED', 'ERROR', 'OK', 'FINISHED', 'WARNING', 'RUNNING', 'CANCELED')
  THEN
    RAISE EXCEPTION 'MS ETL: the alowed status is:''ERROR'', ''START'' ''OK'', ''WARNING'', ''RUNNING'';';
    RETURN COALESCE($1, -1);
  END IF;

  --RAISE WARNING 'Params pid(%)', pid;   
  --RAISE WARNING 'Params graph_param(%)', graph_param;   
  --RAISE WARNING 'Params mode_param(%)', mode_param;   
  --RAISE WARNING 'Params status_param(%)', status_param;   

  SELECT s.id
  INTO var_schedule_id
  FROM schedule s
  WHERE
    s.is_deleted = FALSE
    AND
    s.r_project = pid
    AND
    s.gooddata_schedule = schedule_id_param
  LIMIT 1;

  --RAISE WARNING 'Params var_schedule_id(%)', var_schedule_id;
  IF var_schedule_id IS NOT NULL
  THEN
    rowcount := 0;
    IF status_param = 'STARTED'
    THEN

      --RAISE WARNING 'Params STARTED section(%)', 1;

      UPDATE running_executions
      SET
        event_start     = COALESCE(time_param, now()),
        event_end       = NULL,
        status          = 'RUNNING',
        detailed_status = detailed_status_param,
        request_id      = request_id_param
      WHERE schedule_id = var_schedule_id;

      INSERT INTO running_executions (schedule_id, event_start, status, detailed_status)
        SELECT
          var_schedule_id,
          COALESCE(time_param, now()),
          'RUNNING',
          detailed_status_param
        WHERE NOT EXISTS(SELECT 1
                         FROM running_executions
                         WHERE schedule_id = var_schedule_id);

      INSERT INTO execution_log (r_schedule, status, detailed_status, event_start, request_id)
        SELECT
          s.id,
          'RUNNING',
          detailed_status_param,
          COALESCE(time_param, now()),
          request_id_param
        FROM schedule s
        WHERE s.id = var_schedule_id;

      GET DIAGNOSTICS rowcount = ROW_COUNT;

      --RAISE WARNING 'Params number of ROWS(%)', rowcount;     

    ELSEIF status_param IN ('ERROR', 'FINISHED', 'OK')
      THEN

        --RAISE WARNING 'Params ERROR section(%)', 1; 

        SELECT CASE
               WHEN status_param = 'ERROR'
                 THEN r.number_of_consequent_errors + 1
               ELSE 0
               END
        INTO var_number_of_consequent_errors
        FROM running_executions r
        WHERE schedule_id = var_schedule_id;


        UPDATE running_executions
        SET
          event_end                   = COALESCE(time_param, now()),
          status                      = status_param,
          detailed_status             = detailed_status_param,
          number_of_consequent_errors = var_number_of_consequent_errors
        WHERE schedule_id = var_schedule_id AND COALESCE(time_param, now()) > event_start;

        UPDATE execution_log l_main
        SET
          status          = status_param,
          detailed_status = detailed_status_param,
          event_end       = COALESCE(time_param, now()),
          error_text      = error_text_param
        FROM execution_log l
          INNER JOIN schedule s ON l.r_schedule = s.id
        WHERE
          l.status = 'RUNNING'
          AND
          l_main.id = l.id
          AND
          l.request_id = request_id_param;


        GET DIAGNOSTICS rowcount = ROW_COUNT;

        --RAISE WARNING 'Params number of ROWS(%)', rowcount;     


    END IF;
  END IF;

  IF rowcount = 0
  THEN
    -- If the rowcount is 0, something went wrong and we need to log it
    --RAISE WARNING 'Error section(%)', rowcount;       
    INSERT INTO dump_log (project_pid, schedule_id, graph_name, mode, text) VALUES
      (pid, schedule_id_param, graph_param, mode_param,
       status_param || ' ' || detailed_status_param || ' ' || CAST(time_param AS TEXT) || ' ' || request_id_param);
  END IF;

  RETURN rowcount;

END;
$_$;


--
-- Name: log_execution_new(character varying, character varying, character varying, character varying, character varying, timestamp with time zone); Type: FUNCTION; Schema: log2; Owner: -
--

CREATE FUNCTION log_execution_new(pid character varying, graph_param character varying, mode_param character varying, status_param character varying, detailed_status_param character varying, time_param timestamp with time zone) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
DECLARE 
	rowcount INTEGER;
	param_schedule_id INTEGER;	
BEGIN

  IF status_param not in ('STARTED','ERROR','OK','FINISHED','WARNING','RUNNING') then
        RAISE EXCEPTION 'MS ETL: the alowed status is:''ERROR'', ''START'' ''OK'', ''WARNING'', ''RUNNING'';';
        RETURN COALESCE($1,-1);
  END IF;

  SELECT s.id INTO param_schedule_id FROM log2.schedule s
  WHERE 
	s.is_deleted = false
		AND
	s.r_project = pid 
		AND 
	s.graph_name = graph_param 
		AND 
	(((s.mode IS NULL OR s.mode = '') and (mode_param IS NULL OR mode_param = '')) OR s.mode = mode_param)
  LIMIT 1;	

  IF (status_param  = 'STARTED' AND param_schedule_id IS NOT NULL) THEN

	UPDATE log2.running_executions 
		SET 
		  event_start		=	COALESCE(time_param,now()), 
		  event_end  		= 	NULL,
		  status 		= 	'RUNNING',
		  detailed_status 	=	detailed_status_param  
		WHERE schedule_id=param_schedule_id;
		
	INSERT INTO log2.running_executions (schedule_id, event_start, status, detailed_status)
        SELECT param_schedule_id, COALESCE(time_param,now()), 'RUNNING',detailed_status_param
        WHERE NOT EXISTS (SELECT 1 FROM log2.running_executions WHERE schedule_id=param_schedule_id);	

	INSERT INTO log2.execution_log (r_schedule,status,detailed_status,event_start)
	SELECT s.id,'RUNNING',detailed_status_param,COALESCE(time_param,now())
	FROM log2.schedule s 
	WHERE s.id = param_schedule_id;

        GET DIAGNOSTICS rowcount = ROW_COUNT; 	

  ELSIF (((status_param = 'ERROR') OR (status_param = 'FINISHED') OR (status_param = 'OK')) AND param_schedule_id IS NOT NULL ) THEN

	UPDATE log2.running_executions 
	SET 
	  event_end  		= 	COALESCE(time_param,now()),
	  status 		= 	status_param,
	  detailed_status 	=	detailed_status_param  
	WHERE schedule_id=param_schedule_id;
		
	UPDATE log2.execution_log l_main
		SET 
			status = status_param,
			detailed_status = detailed_status_param,
			event_end = COALESCE(time_param,now())
	FROM log2.execution_log l
	WHERE NOT EXISTS 
		(
			SELECT l2.id  
			FROM log2.execution_log l2 
			WHERE l2.r_schedule = l.r_schedule AND l2.status = 'RUNNING' AND l2.id > l.id
		)
	AND 
		l.status = 'RUNNING' 
	AND 
		l_main.id = l.id 
	AND
		l.r_schedule = param_schedule_id;

        GET DIAGNOSTICS rowcount = ROW_COUNT; 	
	

  END IF;

  IF (rowcount = 0) THEN
	-- If the rowcount is 0, something went wrong and we need to log it
	INSERT INTO log2.dump_log (project_pid,graph_name,mode,text) VALUES (pid,graph_param,mode_param,status_param || ' ' || detailed_status_param || ' ' ||  CAST(time_param as text));
  END IF;

  RETURN rowcount;	


  
END;
$_$;


--
-- Name: log_id(); Type: FUNCTION; Schema: log2; Owner: -
--

CREATE FUNCTION log_id() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ 
BEGIN
    if NEW.run_id is null  then 
    NEW.run_id := NEW.id; 
    end if;
    RETURN NEW;
END;
$$;


--
-- Name: person_stamp(); Type: FUNCTION; Schema: log2; Owner: -
--

CREATE FUNCTION person_stamp() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ 
BEGIN
    NEW.updated_at := current_timestamp; 
    NEW.updated_by  := user; 
    RETURN NEW;
END;
$$;


--
-- Name: update_project_from_stage(); Type: FUNCTION; Schema: log2; Owner: -
--

CREATE FUNCTION update_project_from_stage() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE PROJECT_CATEGORY_ID TEXT;
BEGIN
	SELECT value
	INTO PROJECT_CATEGORY_ID
	FROM log2.settings s
	WHERE s.key = 'project_maintanence_category';

	-- Insert new values to log2.project table
	INSERT INTO log2.project
	SELECT p.de_project_pid as project_pid,p.de_operational_status as status,p.name as name,COALESCE(u.name,p.de_solution_engineer) as ms_person 
	FROM stage.project p 
	LEFT OUTER JOIN stage.user u ON u.id = p.ownerid
	WHERE 
		p.categoryid= PROJECT_CATEGORY_ID
			AND 
		p.de_project_pid != '' 
			AND 
		p.de_project_pid NOT IN (SELECT project_pid FROM log2.project);

	-- Update changed values
	UPDATE log2.project p_main
		SET 
			status = p.de_operational_status,
			name = p.name,
			ms_person = COALESCE(u.name,p.de_solution_engineer)
	FROM log2.project p_log
	INNER JOIN stage.project p ON p.de_project_pid = p_log.project_pid
	LEFT OUTER JOIN stage.user u ON u.id = p.ownerid
	WHERE 
		p.categoryid = PROJECT_CATEGORY_ID 
			AND 
		p_main.project_pid = p_log.project_pid
			AND 
		(
			(p_log.status != p.de_operational_status) 
				OR 
			(p_log.name != p.name) 
			OR 
			(p_log.ms_person != COALESCE(u.name,p.de_solution_engineer))
		);

	-- SET Is_deleted flag

	UPDATE log2.project p_main
		SET 
			is_deleted = true
	WHERE p_main.project_pid NOT IN (SELECT de_project_pid FROM stage.project WHERE categoryid = PROJECT_CATEGORY_ID );


        --- If someone put back deleted project, we put deleted flag to false			

	UPDATE log2.project p_main
		SET 
			is_deleted = false
	WHERE 
		p_main.project_pid IN (SELECT de_project_pid FROM stage.project WHERE categoryid = PROJECT_CATEGORY_ID )
			AND
		p_main.is_deleted = true;
			
		
	RETURN 1;
END;
$$;


--
-- Name: update_schedule_from_stage(); Type: FUNCTION; Schema: log2; Owner: -
--

CREATE FUNCTION update_schedule_from_stage() RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE SCHEDULE_CATEGORY_ID TEXT;
BEGIN
	SELECT value
	INTO SCHEDULE_CATEGORY_ID
	FROM log2.settings s
	WHERE s.key = 'task_maintanence_category';

	-- Insert new values to Schedule table
	

	INSERT INTO log2.schedule (graph_name,mode,server,cron,r_project)
	SELECT 
		temp_stage.graph as graph_name,
		temp_stage.mode as mode,
		temp_stage.server as server,
		temp_stage.cron as cron,
		temp_stage.project_pid as r_project
	FROM (
		--Join to match Attask task information with project information
		SELECT 
			stage_task.de_graph as graph,
			stage_task.de_mode as mode,
			stage_project.de_project_pid as project_pid,
			stage_task.de_cron as cron,
			stage_task.de_server as server
		FROM stage.task stage_task 
		LEFT OUTER JOIN stage.project stage_project ON stage_project.id = stage_task.projectid
		WHERE stage_task.categoryid = SCHEDULE_CATEGORY_ID
	) temp_stage 
	-- Find the combination of project_pid,graph,mode which is not currently in schedule table
	LEFT OUTER JOIN log2.schedule s ON 
				s.r_project = temp_stage.project_pid 
			AND 
				s.graph_name = temp_stage.graph
			AND 	
				(
					(temp_stage.mode IS NULL AND s.mode IS NULL) 
						OR 
					(temp_stage.mode = s.mode )
				)
	WHERE s.id IS NULL;

	-- Update changed schedules
	
	UPDATE log2.schedule s_main
	SET
		cron = temp_stage.cron,
		server = temp_stage.server
	FROM
	(
		--Join to match Attask task information with project information
		SELECT 
			stage_task.de_graph as graph,
			stage_task.de_mode as mode,
			stage_project.de_project_pid as project_pid,
			stage_task.de_cron as cron,
			stage_task.de_server as server
		FROM stage.task stage_task 
		INNER JOIN stage.project stage_project ON stage_project.id = stage_task.projectid
		WHERE stage_task.categoryid = SCHEDULE_CATEGORY_ID
	) temp_stage 
	-- Join current schedules
	INNER JOIN log2.schedule s ON 
				s.r_project = temp_stage.project_pid 
			AND 
				s.graph_name = temp_stage.graph
			AND 	
				(
					(temp_stage.mode IS NULL AND s.mode IS NULL) 
						OR 
					(temp_stage.mode = s.mode )
				)
	WHERE (temp_stage.cron != s.cron OR temp_stage.server != s.server) AND s_main.id = s.id;


	-- Delete deleted projects


	UPDATE log2.schedule s_main
		SET is_deleted = true
	FROM log2.schedule s
	LEFT OUTER JOIN (
		--Join to match Attask task information with project information
		SELECT 
			stage_task.id as id,
			stage_task.de_mode as mode,
			stage_task.de_graph as graph,
			stage_project.de_project_pid as project_pid,
			stage_task.de_server as server
		FROM stage.task stage_task 
		INNER JOIN stage.project stage_project ON stage_project.id = stage_task.projectid
		WHERE stage_task.categoryid = SCHEDULE_CATEGORY_ID
	) temp_stage ON  
				s.r_project = temp_stage.project_pid 
			AND 
				s.graph_name = temp_stage.graph
			AND 	
				(
					(temp_stage.mode IS NULL AND s.mode IS NULL) 
						OR 
					(temp_stage.mode = s.mode )
				)
        WHERE temp_stage.id IS NULL AND s_main.id = s.id;					


	-- Un-delete deleted schedules
	UPDATE log2.schedule s_main
		SET is_deleted = false
	FROM log2.schedule s
	INNER JOIN (
		--Join to match Attask task information with project information
		SELECT 
			stage_task.id as id,
			stage_task.de_mode as mode,
			stage_task.de_graph as graph,
			stage_project.de_project_pid as project_pid,
			stage_task.de_server as server
		FROM stage.task stage_task 
		INNER JOIN stage.project stage_project ON stage_project.id = stage_task.projectid
		WHERE stage_task.categoryid = SCHEDULE_CATEGORY_ID
	) temp_stage ON  
				s.r_project = temp_stage.project_pid 
			AND 
				s.graph_name = temp_stage.graph
			AND 	
				(
					(temp_stage.mode IS NULL AND s.mode IS NULL) 
						OR 
					(temp_stage.mode = s.mode )
				)
        WHERE temp_stage.id IS NULL AND s_main.id = s.id AND s.is_deleted = true;	

			
		
	RETURN 1;
END;
$$;


--
-- Name: update_sla_events(integer, integer); Type: FUNCTION; Schema: log2; Owner: -
--

CREATE FUNCTION update_sla_events(start_event_id integer, end_event_id integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE sla_event_start_param timestamp with time zone;
DECLARE sla_event_end_param timestamp with time zone;
DECLARE r_schedule_param INT;

BEGIN

	SELECT e.r_schedule,e.event_start
	INTO r_schedule_param,sla_event_start_param
	FROM log2.execution_log e
	WHERE e.id = start_event_id;

	SELECT e.event_start
	INTO sla_event_end_param
	FROM log2.execution_log e
	WHERE e.id = end_event_id;

	UPDATE log2.execution_log e
		SET sla_event_start = start_event_id
	WHERE e.event_start >= sla_event_start_param AND e.event_start <= sla_event_end_param AND e.r_schedule = r_schedule_param;
	
	RETURN 1;
END;
$$;


SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: active_admin_comments; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE active_admin_comments (
    id integer NOT NULL,
    resource_id character varying(255) NOT NULL,
    resource_type character varying(255) NOT NULL,
    author_id integer,
    author_type character varying(255),
    body text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    namespace character varying(255)
);


--
-- Name: active_admin_comments_id_seq; Type: SEQUENCE; Schema: log2; Owner: -
--

CREATE SEQUENCE active_admin_comments_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: active_admin_comments_id_seq; Type: SEQUENCE OWNED BY; Schema: log2; Owner: -
--

ALTER SEQUENCE active_admin_comments_id_seq OWNED BY active_admin_comments.id;


--
-- Name: admin_users; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE admin_users (
    id integer NOT NULL,
    email character varying(255) DEFAULT ''::character varying NOT NULL,
    encrypted_password character varying(255) DEFAULT ''::character varying NOT NULL,
    reset_password_token character varying(255),
    reset_password_sent_at timestamp without time zone,
    remember_created_at timestamp without time zone,
    sign_in_count integer DEFAULT 0,
    current_sign_in_at timestamp without time zone,
    last_sign_in_at timestamp without time zone,
    current_sign_in_ip character varying(255),
    last_sign_in_ip character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: admin_users_id_seq; Type: SEQUENCE; Schema: log2; Owner: -
--

CREATE SEQUENCE admin_users_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: admin_users_id_seq; Type: SEQUENCE OWNED BY; Schema: log2; Owner: -
--

ALTER SEQUENCE admin_users_id_seq OWNED BY admin_users.id;


--
-- Name: contract; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE contract (
    id integer NOT NULL,
    name character varying(50) DEFAULT 'Empty contract'::character varying NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    is_deleted boolean DEFAULT false,
    customer_id integer,
    updated_by character varying(255),
    sla_enabled boolean DEFAULT false,
    sla_type character varying(255),
    sla_value character varying(255),
    sla_percentage integer,
    monitoring_enabled boolean DEFAULT false,
    monitoring_emails character varying(255),
    monitoring_treshhold integer,
    salesforce_id character varying(50),
    contract_type character varying(50) DEFAULT 'N/A'::character varying,
    token character varying(255),
    documentation_url character varying(255),
    resource character varying(255),
    default_max_number_of_errors integer DEFAULT 0
);


--
-- Name: contract_history; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE contract_history (
    id integer NOT NULL,
    contract_id integer,
    value character varying(250),
    valid_from timestamp without time zone,
    valid_to timestamp without time zone,
    updated_by text,
    key text
);


--
-- Name: contract_history_id_seq; Type: SEQUENCE; Schema: log2; Owner: -
--

CREATE SEQUENCE contract_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contract_history_id_seq; Type: SEQUENCE OWNED BY; Schema: log2; Owner: -
--

ALTER SEQUENCE contract_history_id_seq OWNED BY contract_history.id;


--
-- Name: contract_id_seq; Type: SEQUENCE; Schema: log2; Owner: -
--

CREATE SEQUENCE contract_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: contract_id_seq; Type: SEQUENCE OWNED BY; Schema: log2; Owner: -
--

ALTER SEQUENCE contract_id_seq OWNED BY contract.id;


--
-- Name: customer; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE customer (
    id integer NOT NULL,
    name character varying(50) DEFAULT 'Empty customer'::character varying NOT NULL,
    email character varying(255),
    contact_person character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    is_deleted boolean DEFAULT false,
    updated_by character varying(255)
);


--
-- Name: customer_history; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE customer_history (
    id integer NOT NULL,
    customer_id integer,
    value character varying(250),
    valid_from timestamp without time zone,
    valid_to timestamp without time zone,
    updated_by text,
    key text
);


--
-- Name: customer_history_id_seq; Type: SEQUENCE; Schema: log2; Owner: -
--

CREATE SEQUENCE customer_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customer_history_id_seq; Type: SEQUENCE OWNED BY; Schema: log2; Owner: -
--

ALTER SEQUENCE customer_history_id_seq OWNED BY customer_history.id;


--
-- Name: customer_id_seq; Type: SEQUENCE; Schema: log2; Owner: -
--

CREATE SEQUENCE customer_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: customer_id_seq; Type: SEQUENCE OWNED BY; Schema: log2; Owner: -
--

ALTER SEQUENCE customer_id_seq OWNED BY customer.id;


--
-- Name: dump_log; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE dump_log (
    id integer NOT NULL,
    project_pid character varying(100),
    graph_name character varying(255),
    mode character varying(255),
    text text,
    updated_by character varying(100),
    updated_at timestamp with time zone,
    schedule_id character varying(255)
);


--
-- Name: dump_log_id_seq; Type: SEQUENCE; Schema: log2; Owner: -
--

CREATE SEQUENCE dump_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: dump_log_id_seq; Type: SEQUENCE OWNED BY; Schema: log2; Owner: -
--

ALTER SEQUENCE dump_log_id_seq OWNED BY dump_log.id;


--
-- Name: event_log; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE event_log (
    project_pid character varying(100),
    graph_name character varying(100),
    mode character varying(255),
    severity integer,
    event_type character varying(255),
    text text,
    created_date timestamp with time zone,
    persistent boolean,
    notified boolean,
    updated_date timestamp with time zone,
    id integer NOT NULL,
    key character varying(255),
    event_entity character varying(100),
    pd_event_id character varying(255)
);


--
-- Name: event_log_id_seq; Type: SEQUENCE; Schema: log2; Owner: -
--

CREATE SEQUENCE event_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: event_log_id_seq; Type: SEQUENCE OWNED BY; Schema: log2; Owner: -
--

ALTER SEQUENCE event_log_id_seq OWNED BY event_log.id;


--
-- Name: execution_log; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE execution_log (
    id integer NOT NULL,
    event_start timestamp with time zone DEFAULT now() NOT NULL,
    status character varying(32),
    detailed_status character varying(4096),
    updated_by character varying,
    updated_at timestamp with time zone,
    r_schedule integer,
    event_end timestamp with time zone,
    sla_event_start integer,
    request_id character varying(100),
    pd_event_id character varying(255),
    error_text text
);


--
-- Name: execution_log_id_seq; Type: SEQUENCE; Schema: log2; Owner: -
--

CREATE SEQUENCE execution_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: execution_log_id_seq; Type: SEQUENCE OWNED BY; Schema: log2; Owner: -
--

ALTER SEQUENCE execution_log_id_seq OWNED BY execution_log.id;


--
-- Name: execution_log_tmp; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE execution_log_tmp (
    id integer,
    event_start timestamp with time zone,
    status character varying(32),
    detailed_status character varying(4096),
    updated_by character varying,
    updated_at timestamp with time zone,
    r_schedule integer,
    event_end timestamp with time zone,
    sla_event_start integer,
    request_id character varying(100),
    pd_event_id character varying(255)
);


--
-- Name: execution_order; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE execution_order (
    execution_id integer,
    r_schedule integer,
    e_order integer,
    status character varying(100),
    detailed_status character varying(255),
    event_start timestamp with time zone,
    event_end timestamp with time zone,
    sla_event_start integer
);


--
-- Name: job; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE job (
    id integer NOT NULL,
    job_type_id integer,
    scheduled_at timestamp with time zone,
    scheduled_by character varying(255),
    recurrent boolean,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    cron character varying(255),
    is_disabled boolean DEFAULT false
);


--
-- Name: job_entity; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE job_entity (
    id integer NOT NULL,
    job_id integer,
    r_project character varying(255),
    r_schedule integer,
    r_contract integer,
    status character varying(50) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    r_settings_server integer
);


--
-- Name: job_entity_id_seq; Type: SEQUENCE; Schema: log2; Owner: -
--

CREATE SEQUENCE job_entity_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: job_entity_id_seq; Type: SEQUENCE OWNED BY; Schema: log2; Owner: -
--

ALTER SEQUENCE job_entity_id_seq OWNED BY job_entity.id;


--
-- Name: job_history; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE job_history (
    id integer NOT NULL,
    job_id integer,
    started_at timestamp with time zone,
    finished_at timestamp with time zone,
    status character varying(255),
    log text,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: job_history_id_seq; Type: SEQUENCE; Schema: log2; Owner: -
--

CREATE SEQUENCE job_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: job_history_id_seq; Type: SEQUENCE OWNED BY; Schema: log2; Owner: -
--

ALTER SEQUENCE job_history_id_seq OWNED BY job_history.id;


--
-- Name: job_id_seq; Type: SEQUENCE; Schema: log2; Owner: -
--

CREATE SEQUENCE job_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: job_id_seq; Type: SEQUENCE OWNED BY; Schema: log2; Owner: -
--

ALTER SEQUENCE job_id_seq OWNED BY job.id;


--
-- Name: job_parameter; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE job_parameter (
    id integer NOT NULL,
    job_id integer,
    key character varying(255) NOT NULL,
    value text NOT NULL
);


--
-- Name: job_parameter_id_seq; Type: SEQUENCE; Schema: log2; Owner: -
--

CREATE SEQUENCE job_parameter_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: job_parameter_id_seq; Type: SEQUENCE OWNED BY; Schema: log2; Owner: -
--

ALTER SEQUENCE job_parameter_id_seq OWNED BY job_parameter.id;


--
-- Name: job_type; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE job_type (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    key character varying(255)
);


--
-- Name: mute; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE mute (
    id integer NOT NULL,
    reason text,
    start timestamp without time zone,
    "end" timestamp without time zone,
    admin_user_id integer,
    contract_id integer,
    project_pid character varying(255),
    schedule_id integer,
    disabled boolean DEFAULT false,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: mute_id_seq; Type: SEQUENCE; Schema: log2; Owner: -
--

CREATE SEQUENCE mute_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: mute_id_seq; Type: SEQUENCE OWNED BY; Schema: log2; Owner: -
--

ALTER SEQUENCE mute_id_seq OWNED BY mute.id;


--
-- Name: notification_log; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE notification_log (
    id integer NOT NULL,
    key character varying(255) NOT NULL,
    notification_type character varying(50) NOT NULL,
    pd_event_id character varying(100),
    severity integer NOT NULL,
    subject character varying(255),
    message text,
    note text,
    resolved_by character varying(255),
    resolved_at timestamp without time zone,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: notification_log_id_seq; Type: SEQUENCE; Schema: log2; Owner: -
--

CREATE SEQUENCE notification_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: notification_log_id_seq; Type: SEQUENCE OWNED BY; Schema: log2; Owner: -
--

ALTER SEQUENCE notification_log_id_seq OWNED BY notification_log.id;


--
-- Name: project; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE project (
    project_pid character varying(32) NOT NULL,
    status text,
    name text,
    ms_person text,
    updated_by character varying,
    updated_at timestamp with time zone,
    is_deleted boolean DEFAULT false NOT NULL,
    sla_enabled boolean,
    sla_type character varying(100),
    sla_value character varying(255),
    created_at timestamp with time zone,
    customer_name character varying(255),
    customer_contact_name character varying(255),
    customer_contact_email character varying(255),
    contract_id integer
);


--
-- Name: project_detail; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE project_detail (
    project_pid character varying(32) NOT NULL,
    salesforce_type character varying(255),
    practice_group character varying(255),
    note text,
    solution_architect character varying(255),
    solution_engineer character varying(255),
    confluence character varying(255),
    automatic_validation boolean,
    tier character varying(255),
    working_hours character varying(255),
    time_zone character varying(255),
    restart text,
    tech_user character varying(255),
    uses_ftp boolean,
    uses_es boolean,
    archiver boolean,
    sf_downloader_version character varying(255),
    directory_name character varying(255),
    salesforce_id character varying(255),
    salesforce_name character varying(255),
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL
);


--
-- Name: project_history; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE project_history (
    id integer NOT NULL,
    project_pid text,
    value character varying(250),
    valid_from timestamp with time zone,
    valid_to timestamp with time zone,
    updated_by text,
    key text
);


--
-- Name: project_history_id_seq; Type: SEQUENCE; Schema: log2; Owner: -
--

CREATE SEQUENCE project_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_history_id_seq; Type: SEQUENCE; Schema: log2; Owner: -
--

CREATE SEQUENCE project_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: project_history_id_seq; Type: SEQUENCE OWNED BY; Schema: log2; Owner: -
--

ALTER SEQUENCE project_history_id_seq OWNED BY project_history.id;


--
-- Name: running_executions; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE running_executions (
    id integer NOT NULL,
    schedule_id integer,
    status character varying(255),
    detailed_status character varying(4096),
    request_id character varying(255),
    event_start timestamp with time zone DEFAULT now() NOT NULL,
    event_end timestamp with time zone,
    number_of_consequent_errors integer DEFAULT 0
);


--
-- Name: running_executions_id_seq; Type: SEQUENCE; Schema: log2; Owner: -
--

CREATE SEQUENCE running_executions_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: running_executions_id_seq; Type: SEQUENCE OWNED BY; Schema: log2; Owner: -
--

ALTER SEQUENCE running_executions_id_seq OWNED BY running_executions.id;


--
-- Name: schedule; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE schedule (
    id integer NOT NULL,
    graph_name character varying(255),
    mode character varying(255),
    server character varying(255),
    cron character varying(255),
    r_project character varying(255),
    updated_by character varying,
    updated_at timestamp with time zone,
    is_deleted boolean DEFAULT false NOT NULL,
    main boolean DEFAULT false,
    created_at timestamp with time zone,
    settings_server_id integer,
    gooddata_schedule character varying(255),
    gooddata_process character varying(255),
    max_number_of_errors integer DEFAULT 0
);


--
-- Name: schedule_history; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE schedule_history (
    id integer NOT NULL,
    schedule_id integer,
    key character varying(255),
    value text,
    valid_from timestamp without time zone,
    valid_to timestamp without time zone,
    updated_by character varying(255)
);


--
-- Name: schedule_history_id_seq; Type: SEQUENCE; Schema: log2; Owner: -
--

CREATE SEQUENCE schedule_history_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: schedule_history_id_seq; Type: SEQUENCE OWNED BY; Schema: log2; Owner: -
--

ALTER SEQUENCE schedule_history_id_seq OWNED BY schedule_history.id;


--
-- Name: schedule_id_seq; Type: SEQUENCE; Schema: log2; Owner: -
--

CREATE SEQUENCE schedule_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: schedule_id_seq; Type: SEQUENCE OWNED BY; Schema: log2; Owner: -
--

ALTER SEQUENCE schedule_id_seq OWNED BY schedule.id;


--
-- Name: schema_migrations; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE schema_migrations (
    version character varying(255) NOT NULL
);


--
-- Name: settings; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE settings (
    id integer NOT NULL,
    key text,
    value text,
    note text,
    updated_by character varying,
    updated_at timestamp with time zone
);


--
-- Name: settings_id_seq; Type: SEQUENCE; Schema: log2; Owner: -
--

CREATE SEQUENCE settings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: settings_id_seq; Type: SEQUENCE OWNED BY; Schema: log2; Owner: -
--

ALTER SEQUENCE settings_id_seq OWNED BY settings.id;


--
-- Name: settings_server; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE settings_server (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    server_url character varying(255) NOT NULL,
    webdav_url character varying(255),
    server_type character varying(255) NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    default_account character varying(255)
);


--
-- Name: settings_server_id_seq; Type: SEQUENCE; Schema: log2; Owner: -
--

CREATE SEQUENCE settings_server_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: settings_server_id_seq; Type: SEQUENCE OWNED BY; Schema: log2; Owner: -
--

ALTER SEQUENCE settings_server_id_seq OWNED BY settings_server.id;


--
-- Name: sla_description; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE sla_description (
    id integer NOT NULL,
    sla_description_type character varying(50) DEFAULT 'None'::character varying,
    sla_description_text character varying(200),
    sla_type character varying(100) NOT NULL,
    sla_value character varying(100),
    duration bigint,
    contract_id character varying(10)
);


--
-- Name: sla_description_contract; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE sla_description_contract (
    id integer NOT NULL,
    sla_description_type character varying(100),
    sla_description_text character varying(100),
    sla_type character varying(100),
    sla_value character varying(10),
    duration integer,
    sla_percentage character varying(10),
    sla_achieved character varying(10),
    contract_id character varying(10),
    generated_date character varying(50),
    number_failed_projects integer,
    projects_per_contract integer
);


--
-- Name: taggings; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE taggings (
    id integer NOT NULL,
    tag_id integer,
    taggable_id integer,
    taggable_type character varying(255),
    tagger_id integer,
    tagger_type character varying(255),
    context character varying(128),
    created_at timestamp without time zone
);


--
-- Name: taggings_id_seq; Type: SEQUENCE; Schema: log2; Owner: -
--

CREATE SEQUENCE taggings_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: taggings_id_seq; Type: SEQUENCE OWNED BY; Schema: log2; Owner: -
--

ALTER SEQUENCE taggings_id_seq OWNED BY taggings.id;


--
-- Name: tags; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE tags (
    id integer NOT NULL,
    name character varying(255),
    taggings_count integer DEFAULT 0
);


--
-- Name: tags_id_seq; Type: SEQUENCE; Schema: log2; Owner: -
--

CREATE SEQUENCE tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tags_id_seq; Type: SEQUENCE OWNED BY; Schema: log2; Owner: -
--

ALTER SEQUENCE tags_id_seq OWNED BY tags.id;


--
-- Name: temp_request; Type: TABLE; Schema: log2; Owner: -; Tablespace: 
--

CREATE TABLE temp_request (
    request_id character varying(100)
);


--
-- Name: id; Type: DEFAULT; Schema: log2; Owner: -
--

ALTER TABLE ONLY active_admin_comments ALTER COLUMN id SET DEFAULT nextval('active_admin_comments_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: log2; Owner: -
--

ALTER TABLE ONLY admin_users ALTER COLUMN id SET DEFAULT nextval('admin_users_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: log2; Owner: -
--

ALTER TABLE ONLY contract ALTER COLUMN id SET DEFAULT nextval('contract_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: log2; Owner: -
--

ALTER TABLE ONLY contract_history ALTER COLUMN id SET DEFAULT nextval('contract_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: log2; Owner: -
--

ALTER TABLE ONLY customer ALTER COLUMN id SET DEFAULT nextval('customer_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: log2; Owner: -
--

ALTER TABLE ONLY customer_history ALTER COLUMN id SET DEFAULT nextval('customer_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: log2; Owner: -
--

ALTER TABLE ONLY dump_log ALTER COLUMN id SET DEFAULT nextval('dump_log_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: log2; Owner: -
--

ALTER TABLE ONLY event_log ALTER COLUMN id SET DEFAULT nextval('event_log_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: log2; Owner: -
--

ALTER TABLE ONLY execution_log ALTER COLUMN id SET DEFAULT nextval('execution_log_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: log2; Owner: -
--

ALTER TABLE ONLY job ALTER COLUMN id SET DEFAULT nextval('job_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: log2; Owner: -
--

ALTER TABLE ONLY job_entity ALTER COLUMN id SET DEFAULT nextval('job_entity_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: log2; Owner: -
--

ALTER TABLE ONLY job_history ALTER COLUMN id SET DEFAULT nextval('job_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: log2; Owner: -
--

ALTER TABLE ONLY job_parameter ALTER COLUMN id SET DEFAULT nextval('job_parameter_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: log2; Owner: -
--

ALTER TABLE ONLY mute ALTER COLUMN id SET DEFAULT nextval('mute_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: log2; Owner: -
--

ALTER TABLE ONLY notification_log ALTER COLUMN id SET DEFAULT nextval('notification_log_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: log2; Owner: -
--

ALTER TABLE ONLY project_history ALTER COLUMN id SET DEFAULT nextval('project_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: log2; Owner: -
--

ALTER TABLE ONLY running_executions ALTER COLUMN id SET DEFAULT nextval('running_executions_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: log2; Owner: -
--

ALTER TABLE ONLY schedule ALTER COLUMN id SET DEFAULT nextval('schedule_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: log2; Owner: -
--

ALTER TABLE ONLY schedule_history ALTER COLUMN id SET DEFAULT nextval('schedule_history_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: log2; Owner: -
--

ALTER TABLE ONLY settings ALTER COLUMN id SET DEFAULT nextval('settings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: log2; Owner: -
--

ALTER TABLE ONLY settings_server ALTER COLUMN id SET DEFAULT nextval('settings_server_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: log2; Owner: -
--

ALTER TABLE ONLY taggings ALTER COLUMN id SET DEFAULT nextval('taggings_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: log2; Owner: -
--

ALTER TABLE ONLY tags ALTER COLUMN id SET DEFAULT nextval('tags_id_seq'::regclass);


--
-- Name: IX_id; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY project_history
    ADD CONSTRAINT "IX_id" PRIMARY KEY (id);


--
-- Name: I_id; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY schedule
    ADD CONSTRAINT "I_id" PRIMARY KEY (id);


--
-- Name: PK_event_log_id; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY event_log
    ADD CONSTRAINT "PK_event_log_id" PRIMARY KEY (id);


--
-- Name: PK_id; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY settings
    ADD CONSTRAINT "PK_id" PRIMARY KEY (id);


--
-- Name: Primary_Id; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY dump_log
    ADD CONSTRAINT "Primary_Id" PRIMARY KEY (id);


--
-- Name: admin_notes_pkey; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY active_admin_comments
    ADD CONSTRAINT admin_notes_pkey PRIMARY KEY (id);


--
-- Name: admin_users_pkey; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY admin_users
    ADD CONSTRAINT admin_users_pkey PRIMARY KEY (id);


--
-- Name: customer_history_pkey; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contract_history
    ADD CONSTRAINT customer_history_pkey PRIMARY KEY (id);


--
-- Name: customer_history_pkey1; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY customer_history
    ADD CONSTRAINT customer_history_pkey1 PRIMARY KEY (id);


--
-- Name: customer_pkey; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY contract
    ADD CONSTRAINT customer_pkey PRIMARY KEY (id);


--
-- Name: customer_pkey1; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY customer
    ADD CONSTRAINT customer_pkey1 PRIMARY KEY (id);


--
-- Name: execution_log_pkey; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY execution_log
    ADD CONSTRAINT execution_log_pkey PRIMARY KEY (id);


--
-- Name: job_entity_pkey; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY job_entity
    ADD CONSTRAINT job_entity_pkey PRIMARY KEY (id);


--
-- Name: job_history_pkey; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY job_history
    ADD CONSTRAINT job_history_pkey PRIMARY KEY (id);


--
-- Name: job_parameter_pkey; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY job_parameter
    ADD CONSTRAINT job_parameter_pkey PRIMARY KEY (id);


--
-- Name: job_pkey; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY job
    ADD CONSTRAINT job_pkey PRIMARY KEY (id);


--
-- Name: mute_pkey; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY mute
    ADD CONSTRAINT mute_pkey PRIMARY KEY (id);


--
-- Name: notification_log_pkey; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY notification_log
    ADD CONSTRAINT notification_log_pkey PRIMARY KEY (id);


--
-- Name: project_detail_pkey; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY project_detail
    ADD CONSTRAINT project_detail_pkey PRIMARY KEY (project_pid);


--
-- Name: project_pkey; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY project
    ADD CONSTRAINT project_pkey PRIMARY KEY (project_pid);


--
-- Name: project_project_pid_key; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY project
    ADD CONSTRAINT project_project_pid_key UNIQUE (project_pid);


--
-- Name: running_executions_pkey; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY running_executions
    ADD CONSTRAINT running_executions_pkey PRIMARY KEY (id);


--
-- Name: schedule_history_pkey; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY schedule_history
    ADD CONSTRAINT schedule_history_pkey PRIMARY KEY (id);


--
-- Name: settings_server_pkey; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY settings_server
    ADD CONSTRAINT settings_server_pkey PRIMARY KEY (id);


--
-- Name: sla_description_contract_pkey; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sla_description_contract
    ADD CONSTRAINT sla_description_contract_pkey PRIMARY KEY (id);


--
-- Name: sla_description_pkey; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY sla_description
    ADD CONSTRAINT sla_description_pkey PRIMARY KEY (id, sla_type);


--
-- Name: taggings_pkey; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY taggings
    ADD CONSTRAINT taggings_pkey PRIMARY KEY (id);


--
-- Name: tags_pkey; Type: CONSTRAINT; Schema: log2; Owner: -; Tablespace: 
--

ALTER TABLE ONLY tags
    ADD CONSTRAINT tags_pkey PRIMARY KEY (id);


--
-- Name: IX__dump_log_id; Type: INDEX; Schema: log2; Owner: -; Tablespace: 
--

CREATE INDEX "IX__dump_log_id" ON dump_log USING btree (id);


--
-- Name: IX_order_schedule; Type: INDEX; Schema: log2; Owner: -; Tablespace: 
--

CREATE INDEX "IX_order_schedule" ON execution_order USING btree (r_schedule NULLS FIRST, e_order NULLS FIRST);


--
-- Name: idx_execution_event_start; Type: INDEX; Schema: log2; Owner: -; Tablespace: 
--

CREATE INDEX idx_execution_event_start ON execution_log USING btree (event_start);


--
-- Name: idx_execution_log4; Type: INDEX; Schema: log2; Owner: -; Tablespace: 
--

CREATE INDEX idx_execution_log4 ON execution_log USING btree (status);


--
-- Name: idx_execution_r_schedule; Type: INDEX; Schema: log2; Owner: -; Tablespace: 
--

CREATE INDEX idx_execution_r_schedule ON execution_log USING btree (r_schedule, event_end);


--
-- Name: idx_request_id; Type: INDEX; Schema: log2; Owner: -; Tablespace: 
--

CREATE INDEX idx_request_id ON execution_log USING btree (request_id);


--
-- Name: index_active_admin_comments_on_author_type_and_author_id; Type: INDEX; Schema: log2; Owner: -; Tablespace: 
--

CREATE INDEX index_active_admin_comments_on_author_type_and_author_id ON active_admin_comments USING btree (author_type, author_id);


--
-- Name: index_active_admin_comments_on_namespace; Type: INDEX; Schema: log2; Owner: -; Tablespace: 
--

CREATE INDEX index_active_admin_comments_on_namespace ON active_admin_comments USING btree (namespace);


--
-- Name: index_admin_notes_on_resource_type_and_resource_id; Type: INDEX; Schema: log2; Owner: -; Tablespace: 
--

CREATE INDEX index_admin_notes_on_resource_type_and_resource_id ON active_admin_comments USING btree (resource_type, resource_id);


--
-- Name: index_admin_users_on_email; Type: INDEX; Schema: log2; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_admin_users_on_email ON admin_users USING btree (email);


--
-- Name: index_admin_users_on_reset_password_token; Type: INDEX; Schema: log2; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_admin_users_on_reset_password_token ON admin_users USING btree (reset_password_token);


--
-- Name: index_mute_on_admin_user_id; Type: INDEX; Schema: log2; Owner: -; Tablespace: 
--

CREATE INDEX index_mute_on_admin_user_id ON mute USING btree (admin_user_id);


--
-- Name: index_mute_on_contract_id; Type: INDEX; Schema: log2; Owner: -; Tablespace: 
--

CREATE INDEX index_mute_on_contract_id ON mute USING btree (contract_id);


--
-- Name: index_mute_on_project_pid; Type: INDEX; Schema: log2; Owner: -; Tablespace: 
--

CREATE INDEX index_mute_on_project_pid ON mute USING btree (project_pid);


--
-- Name: index_mute_on_schedule_id; Type: INDEX; Schema: log2; Owner: -; Tablespace: 
--

CREATE INDEX index_mute_on_schedule_id ON mute USING btree (schedule_id);


--
-- Name: index_tags_on_name; Type: INDEX; Schema: log2; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX index_tags_on_name ON tags USING btree (name);


--
-- Name: job_id desc; Type: INDEX; Schema: log2; Owner: -; Tablespace: 
--

CREATE INDEX "job_id desc" ON job_history USING btree (job_id DESC);


--
-- Name: taggings_idx; Type: INDEX; Schema: log2; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX taggings_idx ON taggings USING btree (tag_id, taggable_id, taggable_type, context, tagger_id, tagger_type);


--
-- Name: unique_schema_migrations; Type: INDEX; Schema: log2; Owner: -; Tablespace: 
--

CREATE UNIQUE INDEX unique_schema_migrations ON schema_migrations USING btree (version);


--
-- Name: person_stamp_execution_log; Type: TRIGGER; Schema: log2; Owner: -
--

CREATE TRIGGER person_stamp_execution_log BEFORE INSERT OR UPDATE ON execution_log FOR EACH ROW EXECUTE PROCEDURE person_stamp();


--
-- Name: person_stamp_settings; Type: TRIGGER; Schema: log2; Owner: -
--

CREATE TRIGGER person_stamp_settings BEFORE INSERT OR UPDATE ON settings FOR EACH ROW EXECUTE PROCEDURE person_stamp();


--
-- Name: update_dump_log; Type: TRIGGER; Schema: log2; Owner: -
--

CREATE TRIGGER update_dump_log BEFORE INSERT ON dump_log FOR EACH ROW EXECUTE PROCEDURE person_stamp();


--
-- PostgreSQL database dump complete
--

SET search_path TO log2;

INSERT INTO schema_migrations (version) VALUES ('20130816090336');

INSERT INTO schema_migrations (version) VALUES ('20130816090338');

INSERT INTO schema_migrations (version) VALUES ('20130816090339');

INSERT INTO schema_migrations (version) VALUES ('20130930142437');

INSERT INTO schema_migrations (version) VALUES ('20131002083257');

INSERT INTO schema_migrations (version) VALUES ('20131003082244');

INSERT INTO schema_migrations (version) VALUES ('20131004111421');

INSERT INTO schema_migrations (version) VALUES ('20131007113620');

INSERT INTO schema_migrations (version) VALUES ('20131009105510');

INSERT INTO schema_migrations (version) VALUES ('20131011124553');

INSERT INTO schema_migrations (version) VALUES ('20131011132037');

INSERT INTO schema_migrations (version) VALUES ('20131014071126');

INSERT INTO schema_migrations (version) VALUES ('20131014081355');

INSERT INTO schema_migrations (version) VALUES ('20131014092404');

INSERT INTO schema_migrations (version) VALUES ('20131015144316');

INSERT INTO schema_migrations (version) VALUES ('20131023144037');

INSERT INTO schema_migrations (version) VALUES ('20131024132546');

INSERT INTO schema_migrations (version) VALUES ('20131025131358');

INSERT INTO schema_migrations (version) VALUES ('20131030135333');

INSERT INTO schema_migrations (version) VALUES ('20131101140208');

INSERT INTO schema_migrations (version) VALUES ('20131104112405');

INSERT INTO schema_migrations (version) VALUES ('20131104113541');

INSERT INTO schema_migrations (version) VALUES ('20131105122758');

INSERT INTO schema_migrations (version) VALUES ('20131108091317');

INSERT INTO schema_migrations (version) VALUES ('20131122103426');

INSERT INTO schema_migrations (version) VALUES ('20131126161537');

INSERT INTO schema_migrations (version) VALUES ('20131127152419');

INSERT INTO schema_migrations (version) VALUES ('20140317115515');

INSERT INTO schema_migrations (version) VALUES ('20140430094218');

INSERT INTO schema_migrations (version) VALUES ('20140430094937');

INSERT INTO schema_migrations (version) VALUES ('20140430094938');

INSERT INTO schema_migrations (version) VALUES ('20140430094939');

INSERT INTO schema_migrations (version) VALUES ('20140508204324');

INSERT INTO schema_migrations (version) VALUES ('20140521071258');

INSERT INTO schema_migrations (version) VALUES ('20140528083151');

INSERT INTO schema_migrations (version) VALUES ('20140529111504');

INSERT INTO schema_migrations (version) VALUES ('20140529143647');

INSERT INTO schema_migrations (version) VALUES ('20140606124806');

INSERT INTO schema_migrations (version) VALUES ('20140703093344');

INSERT INTO schema_migrations (version) VALUES ('20180209124500');
