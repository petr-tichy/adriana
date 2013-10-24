class CreateNewScheduleHistoryTable < ActiveRecord::Migration
  def change

    create_table "schedule_history_new" do |t|
      t.references :schedule, index: false
      t.string     "key"
      t.text "value"
      t.datetime "valid_from"
      t.datetime "valid_to"
      t.string "updated_by"
    end

  end


end
