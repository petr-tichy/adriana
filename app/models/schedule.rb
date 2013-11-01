class Schedule < ActiveRecord::Base
  self.table_name = 'schedule'
  self.primary_key = 'id'

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :id,:graph_name, :mode, :cron, :main,:settings_server_id,:gooddata_schedule,:gooddata_process,:r_project,:is_deleted,:updated_by
  belongs_to :settings_server
  validates_presence_of :graph_name,:cron,:settings_server_id

  # attr_accessible :title, :body

  def self.get_public_attributes
    ["graph_name","mode","cron","is_deleted","main","setting_server_id","gooddata_schedule","gooddata_process"]
  end


  def self.get_last_executions
    #select("schedule.id,e.status,e.event_start,e.event_end").joins("INNER JOIN execution_log e ON e.r_schedule = schedule.id").where("NOT EXISTS (SELECT * FROM execution_log e1 WHERE e1.r_schedule = e.r_schedule and e1.id > e.id) and is_deleted = 'f'")
    select("schedule.id,e.status,e.event_start,e.event_end").joins("INNER JOIN execution_log e ON e.r_schedule = schedule.id").where("NOT EXISTS (SELECT * FROM execution_log e1 WHERE e1.r_schedule = e.r_schedule and e1.id > e.id) and is_deleted = 'f'")
  end

  def self.get_last_executions_all
    #select("schedule.id,e.status,e.event_start,e.event_end").joins("INNER JOIN execution_log e ON e.r_schedule = schedule.id").where("NOT EXISTS (SELECT * FROM execution_log e1 WHERE e1.r_schedule = e.r_schedule and e1.id > e.id) and is_deleted = 'f'")
    select("*").joins("INNER JOIN execution_log e ON e.r_schedule = schedule.id").where("NOT EXISTS (SELECT * FROM execution_log e1 WHERE e1.r_schedule = e.r_schedule and e1.id > e.id) and is_deleted = 'f'")
  end

  def self.default
    select("schedule.*,e.status,e.event_start,e.event_end,p.name as project_name,settings_server.name").joins(:settings_server).joins("INNER JOIN project p ON p.project_pid = schedule.r_project").joins("LEFT OUTER JOIN execution_log e ON e.r_schedule = schedule.id").where("NOT EXISTS (SELECT e1.id FROM execution_log e1 WHERE e1.r_schedule = e.r_schedule and e1.id > e.id) and schedule.is_deleted = 'f'")
  end

  def self.with_project
    select("schedule.*,p.name as project_name").joins("INNER JOIN project p ON p.project_pid = schedule.r_project").where("schedule.is_deleted = 'f'")
  end

  def self.mark_deleted(id,user)
    schedule = Schedule.find(id)
    ScheduleHistory.add_change(schedule.id,"is_deleted","true",user)
    schedule.is_deleted = true
    schedule.updated_by = user.id
    schedule.save
  end




end
