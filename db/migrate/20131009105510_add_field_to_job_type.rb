class AddFieldToJobType < ActiveRecord::Migration
  def change

    change_table "job_type" do |t|
      t.string :key
    end

    execute "UPDATE job_type SET key = 'restart' WHERE id = 1"
    execute "UPDATE job_type SET key = 'synchronize_customer' WHERE id = 2"
    execute "UPDATE job_type SET key = 'update_schedule' WHERE id = 3"
    execute "UPDATE job_type SET key = 'update_notification' WHERE id = 4"
  end
end
