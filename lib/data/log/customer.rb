class Customer < ActiveRecord::Base
  self.table_name = 'log3.customer'
  has_many :contract
end
