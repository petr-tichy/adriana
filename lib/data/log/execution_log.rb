
module SLAWatcher
  class ExecutionLog < ActiveRecord::Base
    self.table_name = 'log2.execution_log'

    def self.log_execution(pid,graph_name,mode,status,detailed_status,time = nil)
      #time = 'NULL' if time.nil?
      #mode = 'NULL' if mode.nil?
      find_by_sql ["SELECT log2.log_execution(?,?,?,?,?,?)", pid, graph_name,mode,status,detailed_status,time]
    end

    def self.log_execution_splunk(pid,graph_name,mode,status,detailed_status,time = nil,request_id = nil)
      #time = 'NULL' if time.nil?
      #mode = 'NULL' if mode.nil?
      find_by_sql ["SELECT log2.log_execution_for_splunk(?,?,?,?,?,?,?)", pid, graph_name,mode,status,detailed_status,time,request_id]
    end


    #Post.find_by_sql ["SELECT title FROM posts WHERE author = ? AND created > ?", author_id, start_date]


    def self.get_last_events_in_interval(pid,modes,graph,datefrom)
        mode = "'" + modes.join("','") + "'"
        select("execution_log.r_schedule,s.server as server,s.mode as mode,MAX(execution_log.updated_at) as updated_at").joins("INNER JOIN log2.schedule s ON s.id = execution_log.r_schedule").where("s.r_project = ? AND s.graph_name = ? AND s.mode IN (#{mode}) AND s.is_deleted = 'false' AND execution_log.event_start > ?",pid,graph,datefrom).group("execution_log.r_schedule,s.server,s.mode")
    end

    def self.get_last_starts_of_live_projects
      select("MAX(event_start) as event_start,s.graph_name as graph_name,s.mode as mode,s.r_project as project_pid,execution_log.r_schedule as r_schedule").joins("INNER JOIN log2.schedule s ON s.id = execution_log.r_schedule").joins("INNER JOIN log2.project p ON p.project_pid = s.r_project").where("p.status = 'Live' and p.is_deleted = 'false'").group("execution_log.r_schedule,s.graph_name,s.mode,s.r_project")
    end

    def self.get_run_statistics(day_of_week,statistics_start)
      select("r_schedule,AVG(event_end - event_start) as avg_run").where("EXTRACT(DOW FROM event_start) = ? AND status = 'FINISHED' AND event_start > ?",day_of_week,statistics_start).group("r_schedule")
    end


    def self.get_running_projects(two_days_back)
      select("*").joins("INNER JOIN log2.schedule s ON s.id = execution_log.r_schedule").where("status = 'RUNNING' and event_start > ?",two_days_back)
    end

    def self.get_running_projects_for_sla
      select("execution_log.id,execution_log.r_schedule, s.r_project as project_pid, s.id as r_schedule, s.server as server, execution_log.event_start, execution_log.event_end ").joins("INNER JOIN log2.schedule s ON s.id = execution_log.r_schedule").joins("INNER JOIN log2.project p ON s.r_project = p.project_pid").where("(execution_log.status = 'RUNNING' OR execution_log.status = 'ERROR') AND s.is_deleted = 'false' AND p.status = 'Live' AND NOT EXISTS (SELECT l2.id FROM log2.execution_log l2 WHERE l2.r_schedule = execution_log.r_schedule	AND	l2.id > execution_log.id AND l2.status = 'FINISHED')")
    end

    def self.check_request_id(values)

    end







  end
end