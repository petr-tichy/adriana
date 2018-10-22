module SLAWatcher

  # This test will check if all project were started in time specified in their cron expresion

  class StartedTest < BaseTest


    def initialize()
      super()
      @EVENT_TYPE = "STARTED_TEST"
      @EVENT_TYPE_NOT_ONCE = "STARTED_TEST_NOT_ONCE"
    end

    def start()
      @@log.info "Starting the #{@EVENT_TYPE} test"
      load_data
      #Lets check if all live schedules were started event once
      #Severity - MEDIUM
      @live_schedules.each do |live_schedule|
        execution = @execution_log.find { |e| e.r_schedule == live_schedule.id }
        notification_log = @notification_logs_not_once.find { |l| l.key == live_schedule.id.to_s }
        if (execution.nil? and notification_log.nil?)
          @new_events << CustomEvent.new(Key.new(live_schedule.id, @EVENT_TYPE_NOT_ONCE), Severity.MEDIUM, "This schedule was not started even once", @now, nil, live_schedule.id)
        end
      end

      # Check if all events were started regarding cron expresion
      # Severity - HIGH
      @execution_log.each do |execution|
        schedule = @live_schedules.find { |s| s.id == execution.r_schedule }
        notification_log = @notification_logs.find { |l| l.key == schedule.id.to_s }
        #Taking only ones with live schedule
        if (!schedule.nil? and schedule.cron != "")
          running_execution = @running_projects.find { |e| e.r_schedule == schedule.id }
          if (schedule.server_type == "cloudconnect")
            now_utc = Time.now.utc
            next_run = Helper.next_run(schedule.cron, execution.event_start.utc, 'UTC')
            running_late_for = ((next_run - now_utc)/1.minute)*(-1)

            if execution.event_end && next_run < execution.event_end.utc
              next_run = Helper.next_run(schedule.cron, execution.event_end.utc, 'UTC')
              running_late_for = ((next_run - now_utc)/1.minute)*(-1)
            end
            # This was added to remove the false alerts in recurent events (when project is running longer and next run is not executed because of last run)
            if (running_execution.nil? and running_late_for > 25 and running_late_for < 60)
              @@log.info("Type: MEDIUM The UTC time is: #{now_utc}, schedule ID is: #{schedule.id}, running_late: #{running_late_for}, cron: #{schedule.cron} execution: #{execution.event_start} #{execution.event_start.utc}, next_run: #{next_run}")
              if (notification_log.nil?)
                @new_events << CustomEvent.new(Key.new(schedule.id, @EVENT_TYPE), Severity.MEDIUM, "Schedule not started - should start: #{next_run.in_time_zone("CET")}", @now, nil, schedule.id)
              else
                @new_events << CustomEvent.new(Key.new(schedule.id, @EVENT_TYPE), Severity.MEDIUM, "Schedule not started - should start: #{next_run.in_time_zone("CET")}", @now, nil, schedule.id, notification_log.id)
              end
            elsif (running_execution.nil? and running_late_for >= 60)
              @@log.info("Type: HIGH The UTC time is: #{now_utc}, schedule ID is: #{schedule.id}, running_late: #{running_late_for}, cron: #{schedule.cron} execution: #{execution.event_start} #{execution.event_start.utc}, next_run: #{next_run}")
              if (notification_log.nil?)
                @new_events << CustomEvent.new(Key.new(schedule.id, @EVENT_TYPE), Severity.HIGH, "Schedule not started - should start: #{next_run.in_time_zone("CET")}", @now, nil, schedule.id)
              else
                @new_events << CustomEvent.new(Key.new(schedule.id, @EVENT_TYPE), Severity.HIGH, "Schedule not started - should start: #{next_run.in_time_zone("CET")}", @now, nil, schedule.id, notification_log.id)
              end
            end
          else
            # Legacy Clover nodes have CRON running in CET Timezone
            next_run = Helper.next_run(schedule.cron, execution.event_start.localtime, 'CET')
            running_late_for = ((next_run - Time.now)/1.minute)*(-1)
            # This was added to remove the false alerts in recurent events (when project is running longer and next run is not executed because of last run)
            if (running_execution.nil? and running_late_for > 25 and running_late_for < 60)
              if (notification_log.nil?)
                @new_events << CustomEvent.new(Key.new(schedule.id, @EVENT_TYPE), Severity.MEDIUM, "Schedule not started - should start: #{next_run}", @now, nil, schedule.id)
              else
                @new_events << CustomEvent.new(Key.new(schedule.id, @EVENT_TYPE), Severity.MEDIUM, "Schedule not started - should start: #{next_run}", @now, nil, schedule.id, notification_log.id)
              end
            elsif (running_late_for >= 60)
              if (notification_log.nil?)
                @new_events << CustomEvent.new(Key.new(schedule.id, @EVENT_TYPE), Severity.HIGH, "Schedule not started - should start: #{next_run}", @now, nil, schedule.id)
              else
                @new_events << CustomEvent.new(Key.new(schedule.id, @EVENT_TYPE), Severity.HIGH, "Schedule not started - should start: #{next_run}", @now, nil, schedule.id, notification_log.id)
              end
            end
          end
        end

      end
      @@log.info "The test #{@EVENT_TYPE} has finished. Created #{@new_events.count} events"
      @new_events
    end

    def load_data()
      @now = DateTime.now
      @execution_log = ExecutionLog.get_last_starts_of_live_projects
      @running_projects = ExecutionLog.get_running_projects(DateTime.now - 24.hour)
      @live_schedules = Schedule.load_schedules_of_live_projects
      @notification_logs = NotificationLog.where(notification_type: @EVENT_TYPE, created_at: (@now - 4.hour)..@now)
      @notification_logs_not_once = NotificationLog.where(notification_type: @EVENT_TYPE_NOT_ONCE, updated_at: (@now - 1.day)..@now)
      @new_events = []

    end


  end


end
