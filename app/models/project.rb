class Project < ActiveRecord::Base
  self.table_name = 'project'
  self.primary_key = 'project_pid'
  #set_primary_key "project_pid"

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable

  def self.get_public_attributes
    ["status","name","ms_person","sla_enabled","sla_type","sla_value","customer_name","customer_contact_name","customer_contact_email"]
  end


  # Setup accessible (or protected) attributes for your model
  attr_accessible :status, :name, :ms_person,:sla_enabled,:sla_type,:sla_value,:customer_name,:customer_contact_name,:customer_contact_email
  # attr_accessible :title, :body
end
