module SLAWatcher


  # This test will control TWO live project running on prod2 and prod3 if they are executed periodicaly
  # This graphs should be executed every 15mins on each servers

  class FinishedTest < BaseTest


    def initialize(events)
      super(events)
      @EVENT_TYPE       =   "FINISHED_TEST"
      @SEVERITY         =   Severity.MEDIUM
      @STATISTICS_INTERVAL    =   2 #How many months back we are creating statistics
      @WARNING_INTERVAL =   30 #Minutes
    end

    def start()
      @now = Time.now
      load_data

      # Test if project is running more then normaly
      @running_projects.each do |execution|
        statistical_value = @statistics_data.find{|s| s.r_schedule == execution.r_schedule }
        if (!statistical_value.nil? and !statistical_value.avg_run.nil? )

          run_statistical_time =  Helper.interval_to_minutes(statistical_value.avg_run)
          run_actual_time = (@now - execution.event_start)/60
          #@@log.info run_statistical_time
          #@@log.info run_actual_time

          difference = run_actual_time - run_statistical_time
          if (difference > 2*@WARNING_INTERVAL)
            event = CustomEvent.new(Key.new(execution.r_project,execution.graph_name,execution.mode),@SEVERITY+1,@EVENT_TYPE,"Running for too long. Standard: #{(run_statistical_time.round)} minutes Current: #{(run_actual_time.round)} minutes",DateTime.now,false)
            @events.push_event(event)
          elsif (difference > @WARNING_INTERVAL)
            event = CustomEvent.new(Key.new(execution.r_project,execution.graph_name,execution.mode),@SEVERITY,@EVENT_TYPE,"Running for too long. Standard: #{(run_statistical_time.round)} minutes Current: #{(run_actual_time.round)} minutes",DateTime.now,false)
            @events.push_event(event)
          end
        else
          # We don't have enough statistical data to monitor this schedules ... lets create LOW SEVERITY event to let us know
          event = CustomEvent.new(Key.new(execution.r_project,execution.graph_name,execution.mode),Severity.LOW,@EVENT_TYPE,"Not enough statistical data - FINISHED test not applied",DateTime.now,false)
          @events.push_event(event)
        end

      end



    end

    def load_data()
      day_of_week = @now.wday
      start_of_statistics = @now - @STATISTICS_INTERVAL.months
      two_days_back = @now - 2.days
      @statistics_data = ExecutionLog.get_run_statistics(day_of_week,start_of_statistics)
      @running_projects =ExecutionLog.get_running_projects(two_days_back)
    end



  end


end