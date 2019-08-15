create function log_execution_for_splunk(pid character varying, schedule_id_param character varying, request_id_param character varying, graph_param character varying, mode_param character varying, status_param character varying, detailed_status_param character varying, time_param timestamp with time zone, error_text_param text) returns integer
LANGUAGE plpgsql
AS $$
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
$$;
