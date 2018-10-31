class JobHistory < ActiveRecord::Base
  self.table_name = 'job_history'
  has_one :job
end