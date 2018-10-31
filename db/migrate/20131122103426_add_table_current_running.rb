class AddTableCurrentRunning < ActiveRecord::Migration
  def change

    create_table :running_executions do |t|
      t.references :schedule
      t.string :status
      t.string :detailed_status
      t.string :request_id
    end

    execute "ALTER TABLE running_executions ADD COLUMN event_start timestamp with time zone;"
    execute "ALTER TABLE running_executions ALTER COLUMN event_start SET NOT NULL;"
    execute "ALTER TABLE running_executions ALTER COLUMN event_start SET DEFAULT now();"
    execute "ALTER TABLE running_executions ADD COLUMN event_end timestamp with time zone;"
  end


end
