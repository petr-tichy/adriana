class RunningExecutions < ActiveRecord::Base
  self.table_name = 'running_executions'
  belongs_to :schedule
end
