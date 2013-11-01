class JobHistory < ActiveRecord::Base
  self.table_name = 'job_history'
  has_one :job
  attr_accessible :job_id, :started_at, :finished_at,:status,:log


end