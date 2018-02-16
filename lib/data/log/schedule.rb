module SLAWatcher
  class Schedule < ActiveRecord::Base
    self.table_name = 'schedule'
    set_primary_key = :project_pid

    belongs_to :project, :primary_key => "project_pid", :foreign_key => "r_project"
    belongs_to :settings_server
    has_one :running_executions
    has_one :contract, :through => :project
    has_one :customer, :through => :contract
    has_many :mutes
    #belongs_to :contract, :through => :project

    scope :with_mutes, -> { includes(:mutes).includes(:project => :mutes).includes(:contract => :mutes) }

    def self.load_schedules_of_live_projects
      select("schedule.id as id,ss.server_type as server_type,schedule.cron as cron").joins("INNER JOIN project p ON r_project = p.project_pid").joins("INNER JOIN contract c ON c.id = p.contract_id").joins("INNER JOIN settings_server ss ON ss.id = schedule.settings_server_id").where("p.status = ? and schedule.is_deleted = ? and c.contract_type = ? and p.is_deleted = ?","Live",false,"direct",false)
    end

    def self.load_schedules_of_live_projects_main
      Schedule.joins(:project).joins(:contract).where(contract: {contract_type: 'direct'},project:{is_deleted: false,status: 'Live'},schedule: {is_deleted: false})
    end

    def all_mutes
      all_mutes = mutes
      project.present? ? all_mutes + project.all_mutes : all_mutes
    end

    def muted?
      all_mutes.select { |m| m.active? }.any?
    end
  end
end