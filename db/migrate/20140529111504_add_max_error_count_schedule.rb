class AddMaxErrorCountSchedule < ActiveRecord::Migration
  def change
    add_column :schedule,:max_number_of_errors,:integer,:default => 0
    add_column :running_executions,:number_of_consequent_errors,:integer,:default => 0
    add_column :event_log,:pd_event_id,:string
    add_column :execution_log,:pd_event_id,:string
    add_column :contract,:default_max_number_of_errors,:integer,:default => 0
    execute "UPDATE running_executions	SET number_of_consequent_errors = 0 WHERE number_of_consequent_errors IS NULL"


  end


end
