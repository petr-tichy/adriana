class Customer < ActiveRecord::Base
  self.table_name = 'customer'
  has_many :customer_history
  has_many :contracts

  attr_accessible :name,:email,:contact_person

  def self.get_public_attributes
    ["name","email","contact_person"]
  end

  def self.mark_deleted(id,user)
    customer = Customer.find(id)
    CustomerHistory.add_change(customer.id,"is_deleted","true",user)
    customer.is_deleted = true
    customer.updated_by = user.id
    customer.save

    contracts = Contract.where("customer_id = ?",customer.id)
    contracts.each do |c|
      Contract.mark_deleted(c.id,user)
    end
  end


end