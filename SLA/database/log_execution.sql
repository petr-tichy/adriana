CREATE OR REPLACE FUNCTION log2.log_execution(pid character varying, graph_param character varying, mode_param character varying, status_param character varying, detailed_status_param character varying, time_param timestamp with time zone)
  RETURNS integer AS
$BODY$
DECLARE rowcount INTEGER;
BEGIN

  IF status_param not in ('STARTED','ERROR','OK','FINISHED','WARNING','RUNNING') then
        RAISE EXCEPTION 'MS ETL: the alowed status is:''ERROR'', ''START'' ''OK'', ''WARNING'', ''RUNNING'';';
        RETURN COALESCE($1,-1);
  END IF;

  IF (status_param  = 'STARTED') THEN

	INSERT INTO log2.execution_log (r_schedule,status,detailed_status,event_start)
	SELECT s.id,'RUNNING',detailed_status_param,COALESCE(time_param,now())
	FROM log2.schedule s 
	WHERE 
		s.r_project = pid 
			AND 
		s.graph_name = graph_param 
			AND 
		(((s.mode IS NULL OR s.mode = '') and (mode_param IS NULL OR mode_param = '')) OR s.mode = mode_param);
                GET DIAGNOSTICS rowcount = ROW_COUNT; 	

	RETURN rowcount;	

  ELSIF ((status_param = 'ERROR') OR (status_param = 'FINISHED') OR (status_param = 'OK')) THEN

	UPDATE log2.execution_log l_main
		SET 
			status = status_param,
			detailed_status = detailed_status_param,
			event_end = COALESCE(time_param,now())
	FROM log2.execution_log l
	INNER JOIN log2.schedule s ON l.r_schedule = s.id
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
		s.r_project = pid 
	AND 
		s.graph_name = graph_param 
	AND 
		(((s.mode IS NULL OR s.mode = '') and (mode_param IS NULL OR mode_param = '')) OR s.mode = mode_param);

        GET DIAGNOSTICS rowcount = ROW_COUNT; 	
	RETURN rowcount;

  END IF;
	
  
END;
$BODY$
LANGUAGE plpgsql VOLATILE COST 100;
ALTER FUNCTION log2.log_execution(pid character varying, graph_name character varying, mode character varying, status character varying, detailed_status character varying,time_param timestamp with time zone) OWNER TO atom;
