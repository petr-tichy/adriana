module SLAWatcher

  # This test will check if all project were started in time specified in their cron expresion

  class StartedTest < BaseTest


    def initialize(events)
      super(events)
      @EVENT_TYPE       =   "STARTED_TEST"
    end

    def start()
      load_data

      #Lets check if all live schedules were started event once
      #Severity - MEDIUM
      @live_schedules.each do |live_schedule|
        execution = @execution_log.find{|e| e.r_schedule == live_schedule.id}
        if (execution.nil?)
          event = CustomEvent.new(Key.new(live_schedule.r_project,live_schedule.graph_name,live_schedule.mode),Severity.MEDIUM,@EVENT_TYPE,"This schedule was not started even once",DateTime.now,true)
          @events.push_event(event)
        end
      end



      # Check if all events were started regarding cron expresion
      # Severity - HIGH
      @execution_log.each do |execution|
          schedule = @live_schedules.find{|s| s.id  == execution.r_schedule}
          #Taking only ones with live schedule
          if (!schedule.nil?)
              running_execution =  @running_projects.find {|e| e.r_schedule == schedule.id}
              pp running_execution
              if (schedule.server == "CloudConnect")
                now = Time.now.utc
                next_run = Helper.next_run(schedule.cron,execution.event_start.utc,SLAWatcher::UTCTime)
                running_late_for = ((next_run - now)/1.minute)*(-1)
                # This was added to remove the false alerts in recurent events (when project is running longer and next run is not executed because of last run)
                pp running_late_for
                if (!running_execution.nil? and running_late_for > 25 and running_late_for < 60)
                  event = CustomEvent.new(Key.new(schedule.r_project,schedule.graph_name,schedule.mode),Severity.MEDIUM,@EVENT_TYPE,"Schedule not started - should start: #{next_run.in_time_zone("CET")}",DateTime.now,false)
                  @events.push_event(event)
                elsif (running_late_for > 25)
                  event = CustomEvent.new(Key.new(schedule.r_project,schedule.graph_name,schedule.mode),Severity.HIGH,@EVENT_TYPE,"Schedule not started - should start: #{next_run.in_time_zone("CET")}",DateTime.now,false)
                  @events.push_event(event)
                end
              else
                now = Time.now
                next_run = Helper.next_run(schedule.cron,execution.event_start,Time)
                running_late_for = ((next_run - now)/1.minute)*(-1)
                # This was added to remove the false alerts in recurent events (when project is running longer and next run is not executed because of last run)
                if (!running_execution.nil? and running_late_for > 25 and running_late_for < 60)
                  event = CustomEvent.new(Key.new(schedule.r_project,schedule.graph_name,schedule.mode),Severity.MEDIUM,@EVENT_TYPE,"Schedule not started - should start: #{next_run}",DateTime.now,false)
                  @events.push_event(event)
                elsif (running_late_for > 25)
                  event = CustomEvent.new(Key.new(schedule.r_project,schedule.graph_name,schedule.mode),Severity.HIGH,@EVENT_TYPE,"Schedule not started - should start: #{next_run}",DateTime.now,false)
                  @events.push_event(event)
                end
              end
          end

      end



      #pp @execution_log
      #pp @live_schedules
      #event = CustomEvent.new(Key.new(@PROJECT_PID,@GRAPH_NAME,mode),@SEVERITY,@EVENT_TYPE,"The LiveCheck project on server #{mode} is not working",DateTime.now,true)
      #@events.push(event)

    end

    def load_data()
      @execution_log = ExecutionLog.get_last_starts_of_live_projects
      @running_projects = ExecutionLog.get_running_projects(DateTime.now - 1.day)
      @live_schedules = Schedule.load_schedules_of_live_projects
    end



  end


end