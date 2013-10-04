class Job < ActiveRecord::Base
  self.table_name = 'job'
  has_many :job_parameters
  has_many :job_entities
  belongs_to :job_type

end