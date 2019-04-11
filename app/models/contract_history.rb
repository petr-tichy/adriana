class ContractHistory < ActiveRecord::Base
  self.table_name = 'contract_history'
  belongs_to :contract

  def self.add_change(contract_id, key, value, user, is_indirect: false)
    date = DateTime.now
    last_record = select('*').where('contract_id = ? and key = ? and ((valid_from IS NOT NULL AND valid_to IS NULL) OR (valid_from IS NULL and valid_to IS NULL))', contract_id, key).first
    if !last_record.nil?
      last_record.valid_to = date
      last_record.save
      ContractHistory.create(:contract_id => contract_id, :key => key, :value => value, :valid_from => date, :valid_to => nil, :updated_by => user.id, :is_indirect => is_indirect)
    else
      ContractHistory.create(:contract_id => contract_id, :key => key, :value => value, :valid_from => nil, :valid_to => nil, :updated_by => user.id, :is_indirect => is_indirect)
    end
  end

  def related_record
    contract
  end
end