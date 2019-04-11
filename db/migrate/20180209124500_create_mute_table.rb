class CreateMuteTable < ActiveRecord::Migration
  def change
    create_table :mute do |t|
      t.text :reason
      t.datetime :start
      t.datetime :end
      t.integer :admin_user_id
      t.integer :contract_id
      t.string :project_pid
      t.integer :schedule_id
      t.boolean :disabled, default: false
      t.timestamps
    end
    add_index :mute, :admin_user_id
    add_index :mute, :contract_id
    add_index :mute, :project_pid
    add_index :mute, :schedule_id
  end
end
