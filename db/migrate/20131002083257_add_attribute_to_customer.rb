class AddAttributeToCustomer < ActiveRecord::Migration
  def change
     add_column :customer, :is_deleted, :boolean, :default => false
  end


end
