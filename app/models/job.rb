class Job < ActiveRecord::Base
  self.table_name = 'job'
  has_many :job_parameters
  has_many :job_entities
  belongs_to :job_type
  attr_accessible :job_type_id, :status, :scheduled_by,:recurrent,:scheduled_at
  just_define_datetime_picker :scheduled_at, :add_to_attr_accessible => true



end