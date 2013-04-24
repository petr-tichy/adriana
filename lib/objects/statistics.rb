module SLAWatcher

  class Statistics

    def initialize()
      time = Time.new
      @statistics = {}
      values = ExecutionLog.load_projects_statistic
      values.each do |v|
        v.avg_time_double = Helper.interval_to_double(v.avg_time)
        @statistics[v.pid] = v
      end
    end

    def values
      @statistics
    end





  end


end