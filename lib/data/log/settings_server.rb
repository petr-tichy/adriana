class SettingsServer < ActiveRecord::Base
  self.table_name = 'log3.settings_server'
  self.primary_key = 'id'
  has_many :schedules

end
