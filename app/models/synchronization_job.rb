class SynchronizationJob < ActiveRecord::Base
  self.table_name = 'job'
  has_many :job_parameters
  has_many :job_entities
  has_many :job_histories
  belongs_to :job_type
  attr_accessible :job_type_id, :scheduled_by,:recurrent,:scheduled_at
  attr_accessor :settings_server_id,:param_mode,:param_resource,:cron
  just_define_datetime_picker :scheduled_at, :add_to_attr_accessible => true
  validates_presence_of :settings_server_id,:param_mode,:param_resource

end