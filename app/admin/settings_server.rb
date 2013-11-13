ActiveAdmin.register SettingsServer do
    menu :label => "Servers"
    menu :parent => "Settings"

    form do |f|
      f.inputs "Values" do
        f.input :name
        f.input :server_type, :as => :select, :collection => ["cloudconnect", "infra", "bash"]
        f.input :server_url
        f.input :webdav_url
        f.input :default_account
      end
      f.actions
    end





end

