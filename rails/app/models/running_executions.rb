class RunningExecutions < ActiveRecord::Base
  self.table_name = 'running_executions'
  self.primary_key = 'id'
  belongs_to :schedule, :foreign_key => 'schedule_id'
end
