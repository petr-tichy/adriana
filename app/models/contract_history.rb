class ContractHistory < ActiveRecord::Base
  self.table_name = 'contract_history'
  attr_accessible :contract_id,:key,:value,:valid_from,:valid_to,:updated_by

  def self.add_change(contract_id,key,value,user)
    date = DateTime.now
    last_record = select("*").where("contract_id = ? and key = ? and ((valid_from IS NOT NULL AND valid_to IS NULL) OR (valid_from IS NULL and valid_to IS NULL))",contract_id,key).first
    if (!last_record.nil?)
      last_record.valid_to = date
      last_record.save
      ContractHistory.create(:contract_id => contract_id,:key => key,:value => value,:valid_from => date,:valid_to => nil, :updated_by => user.id )
    else
      ContractHistory.create(:contract_id => contract_id,:key => key,:value => value,:valid_from => nil,:valid_to => nil, :updated_by => user.id )
    end

  end

end