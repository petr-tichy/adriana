class Project < ActiveRecord::Base
  self.table_name = 'project'
  self.primary_key = 'project_pid'

  belongs_to :contract, :foreign_key => 'contract_id', :primary_key => 'id'
  has_many :schedules
  has_many :mutes, :foreign_key => 'project_pid'
  validates_presence_of :status, :name, :project_pid, :contract_id

  scope :with_mutes, -> { includes(:mutes).includes(:contract => :mutes) }

  def self.get_public_attributes
    %w( status name ms_person contract_id )
  end

  # Added chaining of deletion to schedules
  def self.mark_deleted(id, user)
    project = Project.find(id)
    ProjectHistory.add_change(project.project_pid, "is_deleted", "true", user)
    project.is_deleted = true
    project.updated_by = user.id
    project.save

    schedules = Schedule.where("r_project = ?", project.project_pid)
    schedules.each do |schedule|
      Schedule.mark_deleted(schedule.id, user)
    end
  end

  def all_mutes
    all_mutes = mutes
    contract.present? ? all_mutes + contract.mutes : all_mutes
  end

  def muted?
    all_mutes.select { |m| m.active? }.any?
  end
end
