class JobType < ActiveRecord::Base
  self.table_name = 'job_type'
  has_many :jobs
end