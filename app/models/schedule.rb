class Schedule < ActiveRecord::Base
  self.table_name = 'schedule'
  self.primary_key = 'id'

  belongs_to :project, :foreign_key => 'r_project', :primary_key => 'project_pid'
  belongs_to :settings_server, :foreign_key => 'settings_server_id', :primary_key => 'id'
  has_many :mutes, :dependent => :delete_all
  has_one :contract, :through => :project
  has_one :customer, :through => :contract
  has_one :running_executions
  validates_presence_of :graph_name, :settings_server_id

  def self.get_public_attributes
    %w[ graph_name mode cron is_deleted main settings_server_id gooddata_schedule gooddata_process max_number_of_errors ]
  end

  default_scope lambda {
    joins(:project).joins(:contract).joins(:customer)
    .includes(:running_executions).includes(:settings_server)
    .eager_load(:mutes).eager_load(:project => :mutes).eager_load(:contract => :mutes)
    .where('schedule.is_deleted = ?', false)
  }
  scope :with_project, lambda {
    select('schedule.*,p.name as project_name').joins('INNER JOIN project p ON p.project_pid = schedule.r_project').where('schedule.is_deleted = ?', false)
  }
  scope :contract_eq, lambda { |contract_id|
    where('project.contract_id = ?', contract_id) unless contract_id.nil?
  }
  scope :project_contains, lambda { |project_contains|
    where('project.name LIKE :name', :name => "%#{project_contains}%") unless project_contains.nil?
  }
  scope :muted, lambda {
    #TODO change to union when Rails supports it properly
    where(:id => (joins(:contract => :mutes).merge(Mute.active).pluck(:id) | joins(:project => :mutes).merge(Mute.active).pluck(:id) | joins(:mutes).merge(Mute.active).pluck(:id)).uniq)
  }
  scope :not_muted, -> { where.not(:id => muted.pluck(:id)) }

  def self.ransackable_scopes(auth_object = nil)
    %i[default with_project contract_eq project_contains]
  end

  def self.get_last_executions
    #select("schedule.id,e.status,e.event_start,e.event_end").joins("INNER JOIN execution_log e ON e.r_schedule = schedule.id").where("NOT EXISTS (SELECT * FROM execution_log e1 WHERE e1.r_schedule = e.r_schedule and e1.id > e.id) and is_deleted = 'f'")
    select('schedule.id,running_executions.status,e.event_start,e.event_end').joins(:running_executions).where('schedule.is_deleted = ?', false)
  end

  def self.get_last_executions_all
    #select("schedule.id,e.status,e.event_start,e.event_end").joins("INNER JOIN execution_log e ON e.r_schedule = schedule.id").where("NOT EXISTS (SELECT * FROM execution_log e1 WHERE e1.r_schedule = e.r_schedule and e1.id > e.id) and is_deleted = 'f'")
    select('*').joins(:running_executions).where('schedule.is_deleted = ?', false)
  end

  def self.load_schedules_of_live_projects
    select('schedule.id as id,ss.server_type as server_type,schedule.cron as cron').joins('INNER JOIN project p ON r_project = p.project_pid').joins('INNER JOIN contract c ON c.id = p.contract_id').joins('INNER JOIN settings_server ss ON ss.id = schedule.settings_server_id').where('p.status = ? and schedule.is_deleted = ? and c.contract_type = ? and p.is_deleted = ?','Live',false,'direct',false)
  end

  def self.load_schedules_of_live_projects_main
    Schedule.joins(:project).joins(:contract).where(contract: {contract_type: 'direct'},project:{is_deleted: false,status: 'Live'},schedule: {is_deleted: false})
  end

  def self.mark_deleted(id, user)
    schedule = Schedule.find(id)
    ScheduleHistory.add_change(schedule.id, 'is_deleted', 'true', user)
    schedule.is_deleted = true
    schedule.updated_by = user.id
    schedule.save
  end

  def all_mutes
    all_mutes = mutes
    project.present? ? all_mutes + project.all_mutes : all_mutes
  end

  def muted?
    all_mutes.select(&:active?).any?
  end

  # For activeadmin filtering
  def name
    "#{id} - #{graph_name}"
  end
end
