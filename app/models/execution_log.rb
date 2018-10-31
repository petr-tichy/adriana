class ExecutionLog < ActiveRecord::Base
  self.table_name = 'execution_log'
  belongs_to :schedule, :primary_key => 'id', :foreign_key => 'r_schedule'
  has_one :project, :through => :schedule

  def self.log_execution(pid, graph_name, mode, status, detailed_status, time = nil)
    find_by_sql ['SELECT log_execution(?,?,?,?,?,?)', pid, graph_name, mode, status, detailed_status, time]
  end

  def self.log_execution_splunk(pid, schedule_id, request_id, graph_name, mode, status, detailed_status, time = nil, error_text = nil, matches_error_filters = nil)
    find_by_sql ['SELECT log_execution_for_splunk(?,?,?,?,?,?,?,?,?,?)', pid, schedule_id, request_id, graph_name, mode, status, detailed_status, time, error_text, matches_error_filters]
  end

  def self.log_execution_api(schedule_id, status, detailed_status, time = nil, request_id = nil)
    find_by_sql ['SELECT log_execution_for_api(?,?,?,?,?)', schedule_id, status, detailed_status, time, request_id]
  end

  def self.get_last_events_in_interval(pid, modes, graph, datefrom)
    mode = "'" + modes.join("','") + "'"
    select('execution_log.r_schedule,s.settings_server_id as server,s.mode as mode,MAX(execution_log.updated_at) as updated_at').joins('INNER JOIN schedule s ON s.id = execution_log.r_schedule').joins('INNER JOIN project p ON p.project_pid = s.r_project').where("s.r_project = ? AND s.graph_name = ? AND s.mode IN (#{mode}) AND s.is_deleted = 'false' AND execution_log.event_start > ?", pid, graph, datefrom).group('execution_log.r_schedule,s.settings_server_id,s.mode')
  end

  def self.get_last_starts_of_live_projects
    select('MAX(event_start) as event_start,MAX(event_end) as event_end,s.graph_name as graph_name,s.mode as mode,s.r_project as project_pid,execution_log.r_schedule as r_schedule').joins('INNER JOIN schedule s ON s.id = execution_log.r_schedule').joins('INNER JOIN project p ON p.project_pid = s.r_project').joins('INNER JOIN contract c ON c.id = p.contract_id').where("p.status = 'Live' and p.is_deleted = 'false' and c.contract_type = 'direct' and s.is_deleted = 'false'").group('execution_log.r_schedule,s.graph_name,s.mode,s.r_project')
  end

  def self.get_run_statistics(day_of_week, statistics_start)
    select('r_schedule,AVG(event_end - event_start) as avg_run').where("EXTRACT(DOW FROM event_start) = ? AND status = 'FINISHED' AND event_start > ? AND (event_end - event_start) > '2 minutes'", day_of_week, statistics_start).group('r_schedule')
  end


  def self.get_running_projects(two_days_back)
    select('*').joins('INNER JOIN schedule s ON s.id = execution_log.r_schedule').joins('INNER JOIN project p ON p.project_pid = s.r_project').where("execution_log.status = 'RUNNING' and event_start > ?", two_days_back)
  end

  def self.get_running_projects_for_sla
    select('execution_log.id,execution_log.r_schedule, s.r_project as project_pid, s.id as r_schedule, s.server as server, execution_log.event_start, execution_log.event_end ').joins('INNER JOIN schedule s ON s.id = execution_log.r_schedule').joins('INNER JOIN project p ON s.r_project = p.project_pid').joins('INNER JOIN contract c ON c.id = p.contract_id').where("(execution_log.status = 'RUNNING' OR execution_log.status = 'ERROR') AND s.is_deleted = 'false' and c.contract_type = 'direct' AND p.status = 'Live' AND NOT EXISTS (SELECT l2.id FROM execution_log l2 WHERE l2.r_schedule = execution_log.r_schedule	AND	l2.id > execution_log.id AND l2.status = 'FINISHED')")
  end

  def self.get_last_executions
    select('*').joins('INNER JOIN schedule s ON s.id = r_schedule').where("NOT EXISTS (SELECT * FROM execution_log e WHERE e.r_schedule = r_schedule AND e.id > id) AND s.main = 't'")
  end

  def self.get_last_x_executions(number_of_execution, schedule)
    select('*').where('r_schedule = ?', schedule).order('event_start DESC').limit(number_of_execution)
  end

  def self.get_last_n_executions_per_schedule(n = 10)
    find_by_sql("WITH ranked_executions AS ( SELECT id, r_schedule,status,event_start,event_end,pd_event_id,error_text,matches_error_filters,ROW_NUMBER() OVER (PARTITION BY r_schedule ORDER BY id DESC) AS rn FROM execution_log WHERE event_start > now() - interval '7 days') SELECT id,r_schedule,status,event_start,event_end,pd_event_id,error_text,matches_error_filters FROM ranked_executions WHERE rn <= #{n} ORDER BY r_schedule,event_start")
  end

  def self.get_last_five_executions_per_schedule_custom_date(custom_date)
    find_by_sql("WITH ranked_executions AS ( SELECT id, r_schedule,status,event_start,event_end,pd_event_id,error_text,matches_error_filters,ROW_NUMBER() OVER (PARTITION BY r_schedule ORDER BY id DESC) AS rn FROM execution_log WHERE event_start < (to_timestamp('#{custom_date.strftime("%Y%m%d%H%M%S")}', 'YYYYMMDDHH24MISS'))) SELECT id,r_schedule,status,event_start,event_end,pd_event_id,error_text,matches_error_filters FROM ranked_executions WHERE rn <= 5 ORDER BY r_schedule,event_start")
  end
end
