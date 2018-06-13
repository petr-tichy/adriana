class DirectScheduleJob < ActiveRecord::Base
  self.table_name = 'job'
  has_many :job_parameters
  has_many :job_entities
  has_many :job_histories
  belongs_to :job_type

  attr_accessor :settings_server_id,:cron
  just_define_datetime_picker :scheduled_at

  validates_presence_of :settings_server_id,:cron
end