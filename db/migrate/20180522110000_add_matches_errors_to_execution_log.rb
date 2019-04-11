class AddMatchesErrorsToExecutionLog < ActiveRecord::Migration
  def change
    add_column :execution_log,:matches_error_filters,:boolean, :default => false
  end
end
