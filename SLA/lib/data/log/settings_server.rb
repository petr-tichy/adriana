class SettingsServer < ActiveRecord::Base
  self.table_name = 'settings_server'
  set_primary_key = :project_pid
  has_many :schedules

end
