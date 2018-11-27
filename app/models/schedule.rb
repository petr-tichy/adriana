require_relative 'schedule_history'

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
    %w[graph_name mode cron is_deleted main settings_server_id gooddata_schedule gooddata_process max_number_of_errors]
  end

  default_scope lambda {
    joins(:project).joins(:contract).joins(:customer)
      .includes(:running_executions).includes(:settings_server)
      .eager_load(:mutes).eager_load(:project => :mutes).eager_load(:contract => :mutes)
  }
  scope :with_project, lambda {
    joins('INNER JOIN project p ON p.project_pid = schedule.r_project')
  }
  scope :non_deleted, lambda {
    where(schedule: {is_deleted: false})
  }
  scope :contract_eq, lambda { |contract_id|
    where('project.contract_id = ?', contract_id) unless contract_id.nil?
  }
  scope :project_contains, lambda { |project_contains|
    where('project.name LIKE :name', :name => "%#{project_contains}%") unless project_contains.nil?
  }
  scope :muted, lambda {
    #TODO: change to union when Rails supports it properly
    where(:id => (joins(:contract => :mutes).merge(Mute.active).pluck(:id) | joins(:project => :mutes).merge(Mute.active).pluck(:id) | joins(:mutes).merge(Mute.active).pluck(:id)).uniq)
  }
  scope :not_muted, -> { where.not(:id => muted.pluck(:id)) }

  def all_mutes
    all_mutes = mutes
    project.present? ? all_mutes + project.all_mutes : all_mutes
  end

  def active_mutes
    all_mutes.select(&:active?)
  end

  def muted?
    active_mutes.any?
  end

  # For activeadmin filtering
  def name
    "#{id} - #{graph_name}"
  end

  def self.create_with_history(user, schedule_values)
    schedule = Schedule.new
    schedule_values.each_pair do |k, v|
      schedule[k] = v
    end
    schedule.updated_by = user.id

    ActiveRecord::Base.transaction do
      schedule.save

      schedule_values.each_pair do |k, v|
        if Schedule.get_public_attributes.include?(k.to_s)
          ScheduleHistory.add_change(schedule.id, k.to_s, v, user)
        end
      end
    end
  end

  def self.update_with_history(user, schedule_id, schedule_values)
    schedule = Schedule.find(schedule_id)
    changed = false
    ActiveRecord::Base.transaction do
      schedule_values.each_pair do |k, v|
        next if v.to_s == schedule[k].to_s
        changed = true
        schedule[k] = v
        # History update should be done only on public attributes
        if Schedule.get_public_attributes.include?(k.to_s)
          ScheduleHistory.add_change(schedule_id, k.to_s, v, user)
        end
      end

      if changed
        schedule.updated_at = DateTime.now
        schedule.updated_by = user.id
        schedule.save
      end
    end
    changed
  end

  def self.get_by_job_id(job_id)
    Schedule.joins('INNER JOIN job_entity je ON je.r_schedule = schedule.id').where('je.job_id = ?', job_id)
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
    select('schedule.id as id,ss.server_type as server_type,schedule.cron as cron').joins('INNER JOIN project p ON r_project = p.project_pid').joins('INNER JOIN contract c ON c.id = p.contract_id').joins('INNER JOIN settings_server ss ON ss.id = schedule.settings_server_id').where('schedule.is_deleted = ? and c.contract_type = ? and p.is_deleted = ?', false, 'direct', false)
  end

  def self.load_schedules_of_live_projects_main
    Schedule.joins(:project).joins(:contract).where(contract: {contract_type: 'direct'}, project: {is_deleted: false}, schedule: {is_deleted: false})
  end

  def self.mark_deleted(id, user)
    schedule = Schedule.find(id)
    ScheduleHistory.add_change(schedule.id, 'is_deleted', 'true', user)
    schedule.is_deleted = true
    schedule.updated_by = user.id
    schedule.save
  end
end
