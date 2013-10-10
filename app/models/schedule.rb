class Schedule < ActiveRecord::Base
  self.table_name = 'schedule'
  #self.primary_keys = :project_pid

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :r_project, :graph_name, :mode, :server, :cron, :main
  # attr_accessible :title, :body

  def self.get_last_executions
    #select("schedule.id,e.status,e.event_start,e.event_end").joins("INNER JOIN execution_log e ON e.r_schedule = schedule.id").where("NOT EXISTS (SELECT * FROM execution_log e1 WHERE e1.r_schedule = e.r_schedule and e1.id > e.id) and is_deleted = 'f'")
    select("schedule.id,e.status,e.event_start,e.event_end").joins("INNER JOIN execution_log e ON e.r_schedule = schedule.id").where("NOT EXISTS (SELECT * FROM execution_log e1 WHERE e1.r_schedule = e.r_schedule and e1.id > e.id) and is_deleted = 'f'")
  end

  def self.get_last_executions_all
    #select("schedule.id,e.status,e.event_start,e.event_end").joins("INNER JOIN execution_log e ON e.r_schedule = schedule.id").where("NOT EXISTS (SELECT * FROM execution_log e1 WHERE e1.r_schedule = e.r_schedule and e1.id > e.id) and is_deleted = 'f'")
    select("*").joins("INNER JOIN execution_log e ON e.r_schedule = schedule.id").where("NOT EXISTS (SELECT * FROM execution_log e1 WHERE e1.r_schedule = e.r_schedule and e1.id > e.id) and is_deleted = 'f'")
  end

  def self.default
    select("schedule.*,e.status,e.event_start,e.event_end,p.name as project_name").joins("INNER JOIN execution_log e ON e.r_schedule = schedule.id").joins("INNER JOIN project p ON p.project_pid = schedule.r_project").where("NOT EXISTS (SELECT * FROM execution_log e1 WHERE e1.r_schedule = e.r_schedule and e1.id > e.id) and schedule.is_deleted = 'f'")
  end

  def self.with_project
    select("schedule.*,p.name as project_name").joins("INNER JOIN project p ON p.project_pid = schedule.r_project").where("schedule.is_deleted = 'f'")
  end



end
