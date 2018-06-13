class Contract < ActiveRecord::Base
  self.table_name = 'contract'
  self.primary_key = 'id'
  acts_as_taggable

  has_many :contract_history
  has_many :projects, :foreign_key => 'project_pid'
  has_many :mutes
  has_many :schedules, :through => :projects
  belongs_to :customer

  attr_accessor :max_number_of_errors
  validates_presence_of :customer_id, :name

  scope :with_mutes, -> { includes(:mutes) }

  def self.get_public_attributes
    %w( name sla_enabled sla_type sla_value sla_percentage monitoring_enabled
        monitoring_emails monitoring_treshhold token documentation_url
        default_max_number_of_errors contract_type
    )
  end

  def self.contract_by_job_id(job_id)
    select("contract.*").joins("INNER JOIN job_entity je ON  contract.id = je.r_contract").where("je.job_id = ?", job_id).first
  end

  def self.mark_deleted(id, user)
    contract = Contract.find(id)
    ContractHistory.add_change(contract.id, "is_deleted", "true", user)
    contract.is_deleted = true
    contract.updated_by = user.id
    contract.save

    projects = Project.where("contract_id = ?", contract.id)
    projects.each do |p|
      Project.mark_deleted(p.project_pid, user)
    end

  end

  def all_mutes
    mutes
  end

  def muted?
    all_mutes.select { |m| m.active? }.any?
  end
end
