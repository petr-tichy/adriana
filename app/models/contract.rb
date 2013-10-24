class Contract < ActiveRecord::Base
  self.table_name = 'contract'
  has_many :contract_history

  attr_accessible :name

  def self.get_public_attributes
    ["name"]
  end

  def self.contract_by_job_id(job_id)
    select("contract.*").joins("INNER JOIN job_entity je ON  contract.id = je.r_contract").where("je.job_id = ?",job_id).first
  end

end
