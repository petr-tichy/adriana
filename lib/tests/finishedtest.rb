module SLAWatcher


  # This test will control TWO live project running on prod2 and prod3 if they are executed periodicaly
  # This graphs should be executed every 15mins on each servers

  class FinishedTest < BaseTest


    def initialize()
      @EVENT_TYPE       =   "FINISHED_TEST"
      @SEVERITY         =   Severity.MEDIUM
      @STATISTICS_INTERVAL    =   2 #How many months back we are creating statistics
      @WARNING_INTERVAL =   60 #Minutes
    end

    def start()
      @now = Time.now
      @new_events = []
      load_data
      @@log.info "Starting the #{@EVENT_TYPE} test"
      # Test if project is running more then normaly
      @running_projects.each do |execution|
        statistical_value = @statistics_data.find{|s| s.r_schedule == execution.r_schedule }
        notification_log = @notification_logs.find{|n| n.key == execution.id.to_s}
        if (!statistical_value.nil? and !statistical_value.avg_run.nil? )
          run_statistical_time =  Helper.interval_to_minutes(statistical_value.avg_run)
          run_actual_time = (@now - execution.event_start)/60
          difference = run_actual_time - run_statistical_time
          if (difference > 2*@WARNING_INTERVAL)
            if (notification_log.nil?)
              @new_events << CustomEvent.new(Key.new(execution.id,@EVENT_TYPE),@SEVERITY+1,"Running for too long. Standard: #{(run_statistical_time.round)} minutes Current: #{(run_actual_time.round)} minutes",@now,nil,execution.r_schedule)
            else
              @new_events << CustomEvent.new(Key.new(execution.id,@EVENT_TYPE),@SEVERITY+1,"Running for too long. Standard: #{(run_statistical_time.round)} minutes Current: #{(run_actual_time.round)} minutes",@now,nil,execution.r_schedule,notification_log.id)
            end
          elsif (difference > @WARNING_INTERVAL)
            if (notification_log.nil?)
              @new_events << CustomEvent.new(Key.new(execution.id,@EVENT_TYPE),@SEVERITY,"Running for too long. Standard: #{(run_statistical_time.round)} minutes Current: #{(run_actual_time.round)} minutes",@now,nil,execution.r_schedule)
            end
          end
        else
          # We don't have enough statistical data to monitor this schedules ... lets create LOW SEVERITY event to let us know
          if (notification_log.nil?)
            @new_events << CustomEvent.new(Key.new(execution.id,@EVENT_TYPE),Severity.LOW,"Not enough statistical data - FINISHED test not applied",@now,nil,execution.r_schedule)
          end
        end
      end
      @@log.info "The test #{@EVENT_TYPE} has finished. Created #{@new_events.count} events"
      @new_events
    end

    def load_data()
      day_of_week = @now.wday
      start_of_statistics = @now - @STATISTICS_INTERVAL.months
      two_days_back = @now - 2.days
      @statistics_data  = ExecutionLog.get_run_statistics(day_of_week,start_of_statistics)
      #@running_projects = ExecutionLog.get_running_projects(two_days_back)
      @running_projects = ExecutionLog.joins(:schedule).joins(:project).where(execution_log: {status: 'RUNNING', event_start: (two_days_back..@now)},schedule: {is_deleted: false},project: {status: 'Live',is_deleted: false})
      @notification_logs = NotificationLog.where(notification_type: @EVENT_TYPE,created_at: (@now - 3.day)..@now)
    end



  end


end