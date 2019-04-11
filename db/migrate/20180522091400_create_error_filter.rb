class CreateErrorFilter < ActiveRecord::Migration
  def change
    create_table :error_filter do |t|
      t.string :message
      t.integer :admin_user_id
      t.boolean :active, default: true
      t.timestamps
    end
    add_index :error_filter, :admin_user_id
  end
end
