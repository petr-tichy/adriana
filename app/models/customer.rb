require_relative 'customer_history'

class Customer < ActiveRecord::Base
  self.table_name = 'customer'
  has_many :customer_history
  has_many :contracts

  validates_presence_of :name

  scope :with_contracts, lambda {
    joins(:contracts).where(contract: {is_deleted: false}).uniq
  }

  def self.get_public_attributes
    %w[ name email contact_person ]
  end

  def self.mark_deleted(id, user)
    customer = Customer.find(id)
    CustomerHistory.add_change(customer.id, 'is_deleted', 'true', user)
    customer.is_deleted = true
    customer.updated_by = user.id
    customer.save

    contracts = Contract.where('contract.customer_id = ?', customer.id)
    contracts.each do |c|
      Contract.mark_deleted(c.id, user)
    end
  end
end