class Customer < ActiveRecord::Base
  self.table_name = 'customer'
  has_many :customer_history

  attr_accessible :name,:contact_email,:contact_person

  def self.get_public_attributes
    ["name","contact_email","contact_person"]
  end

end
