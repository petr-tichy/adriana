class AddIsIndirectToHistoryTables < ActiveRecord::Migration[5.0]
  def change
    add_column :schedule_history, :is_indirect, :boolean, :default => false
    add_column :project_history, :is_indirect, :boolean, :default => false
    add_column :contract_history, :is_indirect, :boolean, :default => false
    add_column :customer_history, :is_indirect, :boolean, :default => false
  end
end
