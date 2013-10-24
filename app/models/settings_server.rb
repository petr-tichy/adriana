class SettingsServer < ActiveRecord::Base
  self.table_name = 'settings_server'
  self.primary_key = 'id'

  attr_accessible :name, :server_url,:webdav_url,:server_type
end
