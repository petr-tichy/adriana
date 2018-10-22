module SLAWatcher

  class Projects

    def initialize
      time = Time.new
      @projects = {}
      values = ProjectInfo.load_projects("Live")
      values.each do |v|
        if v.cron == nil || v.cron.empty?
          Log.instance.log_warn("The cron expression for pid:#{v.pid} is not valid - warn")
        else
          v.next_run = CrontabParser.next_run(v.cron,time)
        end
        @projects[v.pid] = v
      end

    end

    def values
      @projects
    end




  end


end