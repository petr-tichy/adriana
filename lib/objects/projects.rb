module SLAWatcher

  class Projects

    def initialize()
      time = Time.new
      @projects = {}
      values = ProjectInfo.load_projects("Live")
      values.each do |v|
        Log.instance.log_warn("The cron expresion for pid:#{v.pid} is not valid - warn") if v.cron == nil || v.cron.empty?
        v.next_run = CrontabParser.next_run(v.cron,time) if v.cron != nil && !v.cron.empty?
        @projects[v.pid] = v
      end

    end

    def values
      @projects
    end




  end


end