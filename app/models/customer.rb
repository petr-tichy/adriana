class Customer < ActiveRecord::Base
  self.table_name = 'customer'
  has_many :customer_history

  attr_accessible :name,:contact_email,:contact_person

  def self.get_public_attributes
    ["name","contact_email","contact_person"]
  end

  def self.customer_by_job_id(job_id)
    select("customer.*").joins("INNER JOIN job_entity je ON  customer.id = je.r_customer").where("je.job_id = ?",job_id).first
  end

end
