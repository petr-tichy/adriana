class AddNewFieldToContract < ActiveRecord::Migration
  def change
    add_column :contract,:monitoring_treshhold,:integer

  end
end
