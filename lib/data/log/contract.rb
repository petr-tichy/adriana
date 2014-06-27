class Contract < ActiveRecord::Base
  self.table_name = 'contract'
  belongs_to :customer
end
