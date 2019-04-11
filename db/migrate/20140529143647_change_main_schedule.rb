class ChangeMainSchedule < ActiveRecord::Migration
  def change
    change_column :schedule,:main,:boolean, :default => false
    execute "UPDATE log2.schedule	SET main = false WHERE main IS NULL"
  end
end
