class ChangeJobStartedAtType < ActiveRecord::Migration
  def change
    execute "ALTER TABLE job ALTER COLUMN scheduled_at TYPE timestamp with time zone;"
    execute "ALTER TABLE job_history ALTER COLUMN started_at TYPE timestamp with time zone;"
    execute "ALTER TABLE job_history ALTER COLUMN finished_at TYPE timestamp with time zone;"
  end


end
