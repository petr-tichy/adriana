
module SLAWatcher
  class ExecutionLog < ActiveRecord::Base
    self.table_name = 'log2.execution_log'

    def self.log_execution(pid,graph_name,mode,status,detailed_status,time = nil)
      #time = 'NULL' if time.nil?
      #mode = 'NULL' if mode.nil?
      find_by_sql ["SELECT log2.log_execution(?,?,?,?,?,?)", pid, graph_name,mode,status,detailed_status,time]
    end

    #Post.find_by_sql ["SELECT title FROM posts WHERE author = ? AND created > ?", author_id, start_date]

  end
end