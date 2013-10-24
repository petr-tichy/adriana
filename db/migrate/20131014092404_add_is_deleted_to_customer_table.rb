class AddIsDeletedToCustomerTable < ActiveRecord::Migration
  def change

    change_table :customer do |t|
      t.boolean :is_deleted, :default => false
    end

  end
end
