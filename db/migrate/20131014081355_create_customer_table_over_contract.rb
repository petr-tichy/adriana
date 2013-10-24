class CreateCustomerTableOverContract < ActiveRecord::Migration
  def change
    create_table "customer" do |t|
      t.string  "name", :limit => 50,  :default => "Empty customer", :null => false
      t.string "email", :limit => 255, :null => true
      t.string "contact_person", :limit => 255, :null => true
      t.timestamps
    end

    create_table "customer_history" do |t|
      t.references :customer, index: false
      t.string   "value",       :limit => 250
      t.datetime "valid_from"
      t.datetime "valid_to"
      t.text     "updated_by"
      t.text     "key"
    end

    change_table :contract do |t|
      t.references :customer, index: true
    end
  end
end



