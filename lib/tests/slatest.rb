module SLAWatcher


  # This test will control TWO live project running on prod2 and prod3 if they are executed periodicaly
  # This graphs should be executed every 15mins on each servers

  class SlaTest < BaseTest


    def initialize(events)
      super(events)
      @EVENT_TYPE       =   "SLA_TEST"
      @SEVERITY         =   Severity.MEDIUM
      @TIME_INTERVAL    =   12 #How many hours back are we checking
      @WARNING_INTERVAL =   30 #Minutes
    end

    def start()
      load_data
      @executions = []
      @execution_log.each do |e|
        put_execution(e)
      end
      sort_execution

      # Lets test only project when we should minitor SLA
     @executions.each do |e|
       project = @projects.find{|p| p.project_pid == e[:project_pid]}
       if (!project.nil? and project.sla_enabled == 't')
         start_time = e[:executions].first[:event_start]

         if (project.sla_type == "Fixed Duration")
           duration = Helper.interval_to_minutes(project.sla_value)
           current_duration = ((Time.now - start_time)/60).round

           if (current_duration >= duration)
             event = CustomEvent.new(Key.new(project.r_project,project.graph_name,project.mode),@SEVERITY,@EVENT_TYPE,"We are over SLA by: #{(current_duration - duration)} minutes",DateTime.now,false)
             @events.push_event(event)
           elsif (current_duration >= duration - @WARNING_INTERVAL)
             event = CustomEvent.new(Key.new(project.r_project,project.graph_name,project.mode),@SEVERITY-1,@EVENT_TYPE,"We nearly over SLA (current duration: #{(current_duration )} min, SLA duration: #{duration})",DateTime.now,false)
             @events.push_event(event)
           end
         elsif (project.sla_type == "Fixed Time")
           # All values will be in UTC
           sla_time = Time.parse(project.sla_value + " UTC")
           if (Time.now.utc > sla_time)
             event = CustomEvent.new(Key.new(project.r_project,project.graph_name,project.mode),@SEVERITY,@EVENT_TYPE,"We are over SLA. Should have been loaded till: #{sla_time.in_time_zone("CET")}",DateTime.now,false)
             @events.push_event(event)
           elsif (Time.now.utc > sla_time - @WARNING_INTERVAL.minutes)
             event = CustomEvent.new(Key.new(project.r_project,project.graph_name,project.mode),@SEVERITY-1,@EVENT_TYPE,"We will be soon over SLA. SLA Time: #{sla_time.in_time_zone("CET")}",DateTime.now,false)
             @events.push_event(event)
           end
         end
       end
     end
    end

    def load_data()
      @projects = Schedule.load_schedules_of_live_projects_main
      @execution_log = ExecutionLog.get_running_projects_for_sla
    end

    private

    def put_execution(execution)
      index = @executions.index{|e| e[:project_pid] == execution.project_pid}
      if (index.nil?)
        @executions.push({:project_pid => execution.project_pid, :executions => [{:id => execution.id,:event_start => execution.event_start,:event_end => execution.event_end,:r_schedule => execution.r_schedule}] })
      else
        @executions[index][:executions].push({:id => execution.id,:event_start => execution.event_start,:event_end => execution.event_end,:r_schedule => execution.r_schedule})
      end
    end


    def sort_execution()
      @executions.each do |e|
        e[:executions] = e[:executions].sort {|a,b| a[:event_start] <=> b[:event_start]}
      end
    end

  end


end