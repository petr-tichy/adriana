CREATE OR REPLACE FUNCTION log2.update_schedule_from_stage()
  RETURNS integer AS
$BODY$
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
$BODY$
LANGUAGE plpgsql VOLATILE COST 100;
  
ALTER FUNCTION log2.update_schedule_from_stage() OWNER TO atom;

