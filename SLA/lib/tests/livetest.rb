module SLAWatcher


  # This test will control TWO live project running on prod2 and prod3 if they are executed periodically
  # This graphs should be executed every 15 min on each servers

  class LiveTest < BaseTest


    def initialize
      @PROJECT_PID = 'test'
      @GRAPH_NAME = 'app'
      @MODES = %w(prod2)
      @EVENT_TYPE = 'LIVE_TEST'
      @SEVERITY = Severity.HIGH
      @TIME_INTERVAL = 12 #How many hours back are we checking
      @WARNING_INTERVAL = 45 #Minutes
    end

    def start
      load_data

      #If Some of the executions is totally missing in response from database, we will announce problem
      if @execution_log.length != @MODES.length
        @MODES.each do |mode|
          log = @execution_log.find { |f| f.mode == mode }
          notification_log = @notification_logs.find { |l| l.key == mode }
          if log.nil? and notification_log.nil?
            @new_events << CustomEvent.new(Key.new(mode, @EVENT_TYPE), @SEVERITY, "The LiveCheck project on server #{mode} is not working", @now, nil, nil)
          end
        end
      end

      @execution_log.each do |log|
        number_of_minutes_from_last_finish = (Time.now - log.updated_at)/1.minute
        notification_log = @notification_logs.find { |l| l.key == log.mode }
        if number_of_minutes_from_last_finish > @WARNING_INTERVAL and notification_log.nil?
          @new_events << CustomEvent.new(Key.new(log.mode, @EVENT_TYPE), @SEVERITY, "LiveCheck (#{log.mode}) has not logged in #{@WARNING_INTERVAL} m", @now, nil, nil)
        end
      end
      @new_events
    end

    def load_data
      @execution_log = ExecutionLog.get_last_events_in_interval(@PROJECT_PID, @MODES, @GRAPH_NAME, DateTime.now - @TIME_INTERVAL.hour)
      @new_events = []
      @now = DateTime.now
      @notification_logs = NotificationLog.where(notification_type: @EVENT_TYPE, created_at: (@now - 1.day)..@now)
    end

  end

end
