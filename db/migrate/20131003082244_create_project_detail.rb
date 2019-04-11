class CreateProjectDetail < ActiveRecord::Migration
  def up

    create_table "project_detail", {:id => false} do |t|
      t.string :project_pid
      t.string :salesforce_type
      t.string :practice_group
      t.text :note
      t.string :solution_architect
      t.string :solution_engineer
      t.string :confluence
      t.boolean :automatic_validation
      t.string :tier
      t.string :working_hours
      t.string :time_zone
      t.text :restart
      t.string :tech_user
      t.boolean :uses_ftp
      t.boolean :uses_es
      t.boolean :archiver
      t.string :sf_downloader_version
      t.string :directory_name
      t.string :salesforce_id
      t.string :salesforce_name
      t.timestamps
    end

    execute "ALTER TABLE project_detail ADD PRIMARY KEY (project_pid);"
    execute <<-SQL
       INSERT INTO project_detail(
            project_pid, salesforce_type, practice_group, note, solution_architect,
            solution_engineer, confluence, automatic_validation, tier, working_hours,
            time_zone, restart, tech_user, uses_ftp, uses_es, archiver, sf_downloader_version,
            directory_name, salesforce_id, salesforce_name, created_at, updated_at)
        SELECT
          de_project_pid,
          de_salesforce_type,
          de_practice_group,
          de_note,
          de_solution_architect,
          de_solution_engineer,
          de_confluence,
          CASE
            WHEN de_automatic_validation = 'Yes' THEN true
            ELSE false
          END,
          CAST(de_tier as VARCHAR(10)),
          de_working_hours,
          de_time_zone,
          de_restart,
          de_tech__user,
          CASE
            WHEN de_uses_ftp = 'Yes' THEN true
            ELSE false
          END,
          CASE
            WHEN de_uses_es = 'Yes' THEN true
            ELSE false
          END,
          CASE
            WHEN de_archiver = 'Yes' THEN true
            ELSE false
          END,
          de_sf_downloader_version,
          de_directory_name,
          de_salesforce_id,
          de_salesforce_name,
          now(),
          now()
        FROM stage.project WHERE categoryid = '512c89ec000b3685ee0581379a85f28f' and de_project_pid != '' and de_project_pid IS NOT NULL
    SQL
  end

  def down

    drop_table "project_detail"

  end

end
