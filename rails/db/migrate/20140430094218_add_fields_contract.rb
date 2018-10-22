class AddFieldsContract < ActiveRecord::Migration
  def change
    add_column :contract,:token,:string
    add_column :contract,:documentation_url,:string,:limit => 255
  end


end
