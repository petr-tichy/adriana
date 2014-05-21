module SLAWatcher
  class Schedule < ActiveRecord::Base
    self.table_name = 'log3.schedule'
    belongs_to :project, :primary_key => "project_pid", :foreign_key => "r_project"
    has_one :running_executions
    belongs_to :settings_server
    has_one :contract, :through => :project
    #belongs_to :contract, :through => :project

    def self.load_schedules_of_live_projects
      select("schedule.id as id,ss.server_type as server_type,schedule.cron as cron").joins("INNER JOIN log3.project p ON r_project = p.project_pid").joins("INNER JOIN log3.contract c ON c.id = p.contract_id").joins("INNER JOIN log3.settings_server ss ON ss.id = schedule.settings_server_id").where("p.status = ? and schedule.is_deleted = ? and c.contract_type = ? ","Live",false,"direct")
    end

    def self.load_schedules_of_live_projects_main
      select("*").joins("INNER JOIN log3.project p ON r_project = p.project_pid").where("p.status = ? and schedule.is_deleted = ? and schedule.main = ? and p.contract_id IS NULL","Live",false,true)
    end

  end
end