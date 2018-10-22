class ChangeCustomerAndContractTable < ActiveRecord::Migration
  def change
    add_column :customer,:updated_by,:string
    add_column :contract,:updated_by,:string
  end


end
