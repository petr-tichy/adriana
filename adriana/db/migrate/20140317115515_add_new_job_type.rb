class AddNewJobType < ActiveRecord::Migration
  def up
    execute "INSERT INTO log2.job_type (id,name,created_at,updated_at,key) VALUES (5,'Attask Print',now(),now(),'attask_print_job')"
  end

  def down
    execute "DELETE FROM log2.job_type WHERE key = 'attask_print_job'"
  end
end
