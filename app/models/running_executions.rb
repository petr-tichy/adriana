class RunningExecutions < ActiveRecord::Base
  self.table_name = 'running_executions'
  self.primary_key = 'id'

  belongs_to :schedule, :foreign_key => 'schedule_id'

  def self.get_last_executions_with_contract
    select('running_executions.*,project.contract_id').joins(:schedule).joins('INNER JOIN project project ON project.project_pid = schedule.r_project').where('project.contract_id IS NOT NULL and project.is_deleted = false and schedule.is_deleted = false')
  end
end
