module SLAWatcher
  class Schedule < ActiveRecord::Base
    self.table_name = 'log2.schedule'
    belongs_to :project, :primary_key => "project_pid", :foreign_key => "r_project"
    has_one :running_executions
    belongs_to :settings_server

    def self.load_schedules_of_live_projects
      select("schedule.id as id,ss.server_type as server_type,schedule.cron as cron").joins("INNER JOIN log2.project p ON r_project = p.project_pid").joins("INNER JOIN log2.settings_server ss ON ss.id = schedule.settings_server_id").where("p.status = ? and schedule.is_deleted = ?","Live",false)
    end

    def self.load_schedules_of_live_projects_main
      select("*").joins("INNER JOIN log2.project p ON r_project = p.project_pid").where("p.status = ? and schedule.is_deleted = ? and schedule.main = ? and p.contract_id IS NULL","Live",false,true)
    end

  end
end