class NewJobFields < ActiveRecord::Migration
  def change
    add_column :job,:cron,:string
  end

end
