create function log_execution_for_api(param_gooddata_schedule_id character varying, status_param character varying, detailed_status_param character varying, time_param timestamp with time zone, request_id_param character varying) returns integer
LANGUAGE plpgsql
AS $$
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
$$;
