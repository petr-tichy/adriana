CREATE OR REPLACE FUNCTION log2.update_project_from_stage()
  RETURNS integer AS
$BODY$
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
$BODY$
LANGUAGE plpgsql VOLATILE COST 100;
  
ALTER FUNCTION log2.update_project_from_stage() OWNER TO atom;