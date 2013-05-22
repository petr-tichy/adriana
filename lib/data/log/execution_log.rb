
module SLAWatcher
  class ExecutionLog < ActiveRecord::Base
    self.table_name = 'log2.execution_log'

    def self.log_execution(pid,graph_name,mode,status,detailed_status,time = nil)
      #time = 'NULL' if time.nil?
      #mode = 'NULL' if mode.nil?
      find_by_sql ["SELECT log2.log_execution(?,?,?,?,?,?)", pid, graph_name,mode,status,detailed_status,time]
    end

    #Post.find_by_sql ["SELECT title FROM posts WHERE author = ? AND created > ?", author_id, start_date]


    def self.get_last_events_in_interval(pid,modes,graph,datefrom)
        mode = "'" + modes.join("','") + "'"
        select("execution_log.r_schedule,s.server as server,s.mode as mode,MAX(execution_log.updated_at) as updated_at").joins("INNER JOIN log2.schedule s ON s.id = execution_log.r_schedule").where("s.r_project = ? AND s.graph_name = ? AND s.mode IN (#{mode}) AND execution_log.event_start > ?",pid,graph,datefrom).group("execution_log.r_schedule,s.server,s.mode")
    end

    def self.get_last_starts_of_live_projects
      select("MAX(event_start) as event_start,s.graph_name as graph_name,s.mode as mode,s.r_project as project_pid,execution_log.r_schedule as r_schedule").joins("INNER JOIN log2.schedule s ON s.id = execution_log.r_schedule").joins("INNER JOIN log2.project p ON p.project_pid = s.r_project").where("p.status = 'Live'").group("execution_log.r_schedule,s.graph_name,s.mode,s.r_project")
    end




  end
end