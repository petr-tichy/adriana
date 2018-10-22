module SLAWatcher

  class Timeline
    def initialize
      @current_log_events = Hash.new
      values = ExecutionLog.load_data_about_last_executions
      values.each do |v|
        if (@current_log_events.key?(v.pid)) then
          @current_log_events[v.pid].push(v)
        else
          logs = Array.new
          logs.push(v)
          @current_log_events[v.pid] = logs
        end
      end
    end

    def values
      @current_log_events
    end


  end


end