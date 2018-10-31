class JobParameter < ActiveRecord::Base
  self.table_name = 'job_parameter'
  has_one :job
end