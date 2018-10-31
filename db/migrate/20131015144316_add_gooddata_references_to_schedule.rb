class AddGooddataReferencesToSchedule < ActiveRecord::Migration
  def change
    change_table :schedule do |t|
      t.string :gooddata_schedule,:null => true
      t.string :gooddata_process,:null => true
    end

  end
end
