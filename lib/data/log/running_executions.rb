module SLAWatcher
  class RunningExecutions < ActiveRecord::Base
    self.table_name = 'log3.running_executions'
    belongs_to :schedule

    def self.get_last_executions_with_contract
      select("running_executions.*,project.contract_id").joins(:schedule).joins("INNER JOIN log3.project project ON project.project_pid = schedule.r_project").where("project.contract_id IS NOT NULL and project.is_deleted = false and schedule.is_deleted = false")
    end



  end
end