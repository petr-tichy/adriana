module SLAWatcher


  # This test will control TWO live project running on prod2 and prod3 if they are executed periodicaly
  # This graphs should be executed every 15mins on each servers

  class LiveTest < BaseTest


    def initialize(events)
      super(events)
      @PROJECT_PID      =   "test"
      @GRAPH_NAME       =   "app"
      @MODES            =   ["prod2","prod3"]
      @EVENT_TYPE       =   "LIVE_TEST"
      @SEVERITY         =   Severity.HIGH
      @TIME_INTERVAL    =   12 #How many hours back are we checking
      @WARNING_INTERVAL =   45 #Minutes
    end

    def start()
      load_data
      #If Some of the executions is totally missing in response from database, we will anounce problem
      if (@execution_log.length != @MODES.length) then
        @MODES.each do |mode|
          log = @execution_log.find{|f| f.mode == mode}
          if (log.nil?) then
            event = CustomEvent.new(Key.new(@PROJECT_PID,@GRAPH_NAME,mode),@SEVERITY,@EVENT_TYPE,"The LiveCheck project on server #{mode} is not working",DateTime.now,true,"LiveTest",mode)
            @events.push(event)
          end
        end
      end

      @execution_log.each do |log|
        number_of_minutes_from_last_finish = (Time.now - log.updated_at)/1.minute
        if (number_of_minutes_from_last_finish > @WARNING_INTERVAL)
          event = CustomEvent.new(Key.new(@PROJECT_PID,@GRAPH_NAME,log.mode),@SEVERITY,@EVENT_TYPE,"The LiveCheck project on server #{log.mode} has not logged in last #{@WARNING_INTERVAL} mins",DateTime.now,true,"LiveTest",log.mode)
          @events.push(event)
        end
      end
    end

    def load_data()
      @execution_log = ExecutionLog.get_last_events_in_interval(@PROJECT_PID,@MODES,@GRAPH_NAME,DateTime.now - @TIME_INTERVAL.hour)
    end



  end


end