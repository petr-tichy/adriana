class AddProcessNameToSchedule < ActiveRecord::Migration[5.0]
  def change
    add_column :schedule, :process_name, :string
  end
end
