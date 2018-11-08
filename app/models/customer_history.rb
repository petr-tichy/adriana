class CustomerHistory < ActiveRecord::Base
  self.table_name = 'customer_history'
  belongs_to :customer

  def self.add_change(customer_id,key,value,user)
    date = DateTime.now
    last_record = select("*").where("customer_id = ? and key = ? and ((valid_from IS NOT NULL AND valid_to IS NULL) OR (valid_from IS NULL and valid_to IS NULL))",customer_id,key).first
    if (!last_record.nil?)
      last_record.valid_to = date
      last_record.save
      CustomerHistory.create(:customer_id => customer_id,:key => key,:value => value,:valid_from => date,:valid_to => nil, :updated_by => user.id )
    else
      CustomerHistory.create(:customer_id => customer_id,:key => key,:value => value,:valid_from => nil,:valid_to => nil, :updated_by => user.id )
    end
  end

  def related_record
    customer
  end
end