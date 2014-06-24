class Contract < ActiveRecord::Base
  self.table_name = 'log3.contract'
  belongs_to :customer
end
