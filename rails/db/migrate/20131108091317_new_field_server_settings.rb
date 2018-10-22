class NewFieldServerSettings < ActiveRecord::Migration
  def change
    add_column :settings_server, :default_account, :string
  end


end
