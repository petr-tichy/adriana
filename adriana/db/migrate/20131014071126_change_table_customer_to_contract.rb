class ChangeTableCustomerToContract < ActiveRecord::Migration
  def change

    rename_table(:customer,:contract)
    rename_table(:customer_history,:contract_history)
    remove_column :contract, :contact_email
    remove_column :contract, :contact_person
    rename_column(:contract_history,:customer_id,:contract_id)
    rename_column(:job_entity,:r_customer,:r_contract)
    rename_column(:project,:customer_id,:contract_id)

    execute "UPDATE job_type SET name = 'Synchronize PWB customer', key = 'synchronize_contract' WHERE key = 'synchronize_customer'"
  end


end
