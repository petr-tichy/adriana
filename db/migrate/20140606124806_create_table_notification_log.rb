class CreateTableNotificationLog < ActiveRecord::Migration
  def change
    create_table "notification_log" do |t|
      t.string  "key", :null => false
      t.string "notification_type", :limit => 50, :null => false
      t.string "pd_event_id",:limit => 100, :null => true
      t.integer "severity", :null => false
      t.string "subject"
      t.text "message"
      t.text "note"
      t.string "resolved_by"
      t.datetime "resolved_at"
      t.timestamps
    end
  end

end
