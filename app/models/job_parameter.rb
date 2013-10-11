class JobParameter < ActiveRecord::Base
  self.table_name = 'job_parameter'
  has_one :job
  attr_accessible :job_id, :key, :value
end