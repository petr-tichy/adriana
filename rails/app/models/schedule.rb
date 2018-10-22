class Schedule < ActiveRecord::Base
  self.table_name = 'schedule'
  self.primary_key = 'id'

  belongs_to :settings_server, :foreign_key => 'settings_server_id', :primary_key => 'id'
  belongs_to :project, :foreign_key => 'r_project', :primary_key => 'project_pid'
  has_one :running_executions
  has_one :contract, :through => :project
  has_many :mutes, :dependent => :delete_all
  validates_presence_of :graph_name, :settings_server_id

  def self.get_public_attributes
    %w( graph_name mode cron is_deleted main settings_server_id gooddata_schedule gooddata_process max_number_of_errors )
  end

  scope :default, -> {
    select("schedule.*,running_executions.status,running_executions.event_start,running_executions.event_end,settings_server.name").joins(:running_executions).joins(:settings_server).joins(:project).joins(:project => :contract).where("schedule.is_deleted = ?", false)
  }

  scope :with_project, -> {
    select("schedule.*,p.name as project_name").joins("INNER JOIN project p ON p.project_pid = schedule.r_project").where("schedule.is_deleted = ?", false)
  }

  scope :with_mutes, -> { includes(:mutes).includes(:project => :mutes).includes(:contract => :mutes) }

  scope :contract_eq,
        lambda { |contract_id|
          unless contract_id.nil?
            default.where("project.contract_id = ?", contract_id)
          end
        }

  scope :project_contains,
        lambda { |project_contains|
          unless project_contains.nil?
            default.where("project.name LIKE :name", {:name => "%#{project_contains}%"})
          end
        }

  def self.ransackable_scopes(auth_object = nil)
    [:default, :with_project, :with_mutes, :contract_eq, :project_contains]
  end

  def self.get_last_executions
    #select("schedule.id,e.status,e.event_start,e.event_end").joins("INNER JOIN execution_log e ON e.r_schedule = schedule.id").where("NOT EXISTS (SELECT * FROM execution_log e1 WHERE e1.r_schedule = e.r_schedule and e1.id > e.id) and is_deleted = 'f'")
    select("schedule.id,running_executions.status,e.event_start,e.event_end").joins(:running_executions).where("schedule.is_deleted = ?", false)
  end

  def self.get_last_executions_all
    #select("schedule.id,e.status,e.event_start,e.event_end").joins("INNER JOIN execution_log e ON e.r_schedule = schedule.id").where("NOT EXISTS (SELECT * FROM execution_log e1 WHERE e1.r_schedule = e.r_schedule and e1.id > e.id) and is_deleted = 'f'")
    select("*").joins(:running_executions).where("schedule.is_deleted = ?", false)
  end

  def self.mark_deleted(id, user)
    schedule = Schedule.find(id)
    ScheduleHistory.add_change(schedule.id, "is_deleted", "true", user)
    schedule.is_deleted = true
    schedule.updated_by = user.id
    schedule.save
  end

  def all_mutes
    all_mutes = mutes
    project.present? ? all_mutes + project.all_mutes : all_mutes
  end

  def muted?
    all_mutes.select { |m| m.active? }.any?
  end

  # For activeadmin filtering
  def name
    "#{self.id} - #{self.graph_name}"
  end
end
