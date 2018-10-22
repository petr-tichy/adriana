class AddResourceToContract < ActiveRecord::Migration
  def change
    add_column :contract,:resource,:string
  end
end
