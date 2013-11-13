class SettingsServer < ActiveRecord::Base
  self.table_name = 'settings_server'
  self.primary_key = 'id'
  has_many :schedules

  attr_accessible :name, :server_url,:webdav_url,:server_type,:default_account
end
