class FixSettingServerTable < ActiveRecord::Migration
  def change
    rename_column :settings_server, :type, :server_type
  end


end
