class Project < ActiveRecord::Base
  self.table_name = 'project'
  self.primary_key = 'project_pid'

  has_many :running_executions, :through => :schedules
  has_one :project_detail, :primary_key => 'project_pid', :foreign_key => 'project_pid'
  belongs_to :contract, :foreign_key => 'contract_id', :primary_key => 'id'
  has_many :schedules
  has_many :mutes, :foreign_key => 'project_pid'
  validates_presence_of :status, :name, :project_pid, :contract_id

  default_scope -> { includes(:mutes).includes(:contract => :mutes) }

  scope :muted, lambda {
    #TODO change to union when Rails supports it properly
    where(:project_pid => (joins(:contract => :mutes).merge(Mute.active).pluck(:project_pid) | joins(:mutes).merge(Mute.active).pluck(:project_pid)).uniq)
  }
  scope :not_muted, -> { where.not(:project_pid => muted.pluck(:project_pid)) }

  def self.get_public_attributes
    %w( status name ms_person contract_id )
  end

  def self.load_(status)
    where('status = ?', status)
  end

  # Added chaining of deletion to schedules
  def self.mark_deleted(id, user)
    project = Project.find(id)
    ProjectHistory.add_change(project.project_pid, 'is_deleted', 'true', user)
    project.is_deleted = true
    project.updated_by = user.id
    project.save

    schedules = Schedule.where('r_project = ?', project.project_pid)
    schedules.each do |schedule|
      Schedule.mark_deleted(schedule.id, user)
    end
  end

  def self.load_projects
    find_by_sql(
      "SELECT DISTINCT p.project_pid FROM project p
            INNER JOIN schedule s On p.project_pid = s.r_project
            INNER JOIN settings_server ss ON ss.id = s.settings_server_id
            WHERE ss.server_type = 'cloudconnect' AND p.status = 'Live'"
    )
  end

  def self.load_deleted_projects
    where('is_deleted = ? and p.contract_id IS NULL', 'false')
  end

  def all_mutes
    all_mutes = mutes
    contract.present? ? all_mutes + contract.mutes : all_mutes
  end

  def muted?
    all_mutes.select { |m| m.active? }.any?
  end

  private

  def person_params
    params.permit(:project_pid)
  end
end
