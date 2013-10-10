class JobType < ActiveRecord::Base
  self.table_name = 'job_type'
  self.primary_key = 'id'
  has_many :jobs
end
