class AddNameToSchedule < ActiveRecord::Migration[5.0]
  def change
    add_column :schedule, :name, :string
  end
end
