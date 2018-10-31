ActiveAdmin.register SettingsServer do
  menu :priority => 10
  menu :label => 'Servers'
  menu :parent => 'Settings'
  permit_params :name, :server_url, :webdav_url, :server_type, :default_account

  form do |f|
    f.inputs "Values" do
      f.input :name
      f.input :server_type, :as => :select2, :collection => %w( cloudconnect infra bash )
      f.input :server_url
      f.input :webdav_url
      f.input :default_account
    end
    f.actions
  end
end

