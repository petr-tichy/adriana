class Customer < ActiveRecord::Base
  self.table_name = 'customer'
  has_many :customer_history

  attr_accessible :name,:email,:contact_person

  def self.get_public_attributes
    ["name","email","contact_person"]
  end


end