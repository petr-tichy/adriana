class ChangeScheduleTypes < ActiveRecord::Migration
  def change

    change_column(:schedule, :graph_name, :string,{:limit => 255})
    change_column(:schedule, :mode, :string,{:limit => 255})
    change_column(:schedule, :server, :string,{:limit => 255})
    change_column(:schedule, :cron, :string,{:limit => 255})
    change_column(:schedule, :r_project, :string,{:limit => 255})
  end


end
