require_relative 'project_history'

class Project < ActiveRecord::Base
  self.table_name = 'project'
  self.primary_key = 'project_pid'

  has_many :running_executions, :through => :schedules
  has_one :project_detail, :primary_key => 'project_pid', :foreign_key => 'project_pid'
  belongs_to :contract, :foreign_key => 'contract_id', :primary_key => 'id'
  has_one :customer, :through => :contract
  has_many :schedules, :foreign_key => 'r_project'
  has_many :mutes, :foreign_key => 'project_pid'
  validates_presence_of :name, :project_pid, :contract_id

  default_scope lambda {
    joins(:contract).joins(:customer)
      .eager_load(:mutes).eager_load(:contract => :mutes)
  }

  scope :with_schedules, lambda {
    joins(:schedules).where(schedule: {is_deleted: false}).uniq
  }

  scope :muted, lambda {
    #TODO change to union when Rails supports it properly
    where(:project_pid => (joins(:contract => :mutes).merge(Mute.active).pluck(:project_pid) | joins(:mutes).merge(Mute.active).pluck(:project_pid)).uniq)
  }
  scope :not_muted, -> { where.not(:project_pid => muted.pluck(:project_pid)) }

  def all_mutes
    all_mutes = mutes
    contract.present? ? all_mutes + contract.mutes : all_mutes
  end

  def active_mutes
    all_mutes.select(&:active?)
  end

  def muted?
    active_mutes.any?
  end

  def self.get_public_attributes
    %w( status name ms_person contract_id customer_name customer_contact_name customer_contact_email )
  end

  def self.load_(status)
    where('status = ?', status)
  end

  def self.create_with_history(user, project_values)
    project = self.class.new
    ActiveRecord::Base.transaction do
      project_values.each_pair do |k, v|
        project[k] = v
        if self.class.get_public_attributes.include?(k.to_s)
          ProjectHistory.add_change(project_values['project_pid'], k.to_s, v, user)
        end
      end
      project.save
    end

    project_detail = ProjectDetail.new
    project_detail.project_pid = project.project_pid
    project_detail.save
  end

  def self.update_with_history(user, project_pid, project_values)
    project = Project.find(project_pid)
    changed = false
    ActiveRecord::Base.transaction do
      project_values.each_pair do |k, v|
        next if v.to_s == project[k].to_s
        changed = true
        project[k] = v
        if Project.get_public_attributes.include?(k.to_s)
          ProjectHistory.add_change(project_pid, k.to_s, v, user)
        end
      end

      if changed
        project.updated_at = DateTime.now
        project.updated_by = user.id
        project.save
      end
    end
    changed
  end

  # Added chaining of deletion to schedules
  def self.mark_deleted(id, user, flag: true)
    project = Project.find(id)
    ProjectHistory.add_change(project.project_pid, 'is_deleted', flag.to_s, user)
    project.is_deleted = flag
    project.updated_by = user.id
    project.save

    schedules = Schedule.where('schedule.r_project = ?', project.project_pid)
    schedules.each do |schedule|
      Schedule.mark_deleted(schedule.id, user, flag: flag)
    end
  end

  #TODO change uses of this to use a scope
  def self.load_projects
    find_by_sql(
      "SELECT DISTINCT p.project_pid FROM project p
            INNER JOIN schedule s On p.project_pid = s.r_project
            INNER JOIN settings_server ss ON ss.id = s.settings_server_id
            WHERE ss.server_type = 'cloudconnect'"
    )
  end

  def self.load_deleted_projects
    where('is_deleted = ? and p.contract_id IS NULL', 'false')
  end

  private

  def person_params
    params.permit(:project_pid)
  end
end
