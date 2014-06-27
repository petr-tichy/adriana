class Customer < ActiveRecord::Base
  self.table_name = 'customer'
  has_many :contract
end
