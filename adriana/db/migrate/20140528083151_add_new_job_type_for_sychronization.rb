class AddNewJobTypeForSychronization < ActiveRecord::Migration
  def up
    execute "INSERT INTO log2.job_type (id,name,created_at,updated_at,key) VALUES (6,'Direct Synchronization',now(),now(),'synchronize_direct_schedules')"
  end

  def down
    execute "DELETE FROM log2.job_type WHERE key = 'synchronize_direct_schedules'"
  end
end
