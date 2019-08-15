class CreateNewScheduleHistoryTable < ActiveRecord::Migration
  def change
    rename_table :schedule_history, :schedule_history_old

    create_table "schedule_history" do |t|
      t.references :schedule, index: false
      t.string     "key"
      t.text "value"
      t.datetime "valid_from"
      t.datetime "valid_to"
      t.string "updated_by"
    end



  end


end
