module SLAWatcher

  class Events

    def initialize()
      @events = []
      load_events_from_database
    end


    def push_event(event)
      index = find_event_index(event)
      if (index.nil?)
        @events.push(event)
      else
        update_event(event,index)
      end
    end

    def update_event(event,index)
      # IF event is fired again, we change historical to false, so it would be saved in DB
      old_event = @events[index]
      event.updated_date = DateTime.now
      event.historical = false
      event.created_date = old_event.created_date
      event.notified = old_event.notified
      @events[index] = event
    end


    def find_event_index(event)
      @events.index{|e| e.key.type == event.key.type and e.key.value.to_s == event.key.value.to_s and e.event_type == event.event_type}
    end

    def save
      ActiveRecord::Base.transaction do
        EventLog.delete_all
        @events.each do |e|
          if (!e.historical)
            EventLog.create(e.to_db_entity)
          end
        end
      end
    end

    def mail_status
      body = ""
      @events.each do |e|
        #stage_schedule = @schedule_in_stage.find{|s| s.r_project == e.key.project_pid and s.graph_name = e.graph and s.mode == e.mode}
        schedule = @schedules.find {|s| s.id.to_s == e.key.value.to_s and e.key.type == "SCHEDULE"}
        body << "---------------------------------------- \n"
        body << "Project Name: #{schedule.project.name} Server: #{schedule.settings_server.name} \n"
        body << e.to_s
        body << "---------------------------------------- \n"
      end
      #Pony.mail(:to => "adrian.toman@gooddata.com,jan.cisar@gooddata.com,jiri.stovicek@gooddata.com,miloslav.zientek@gooddata.com",:from => 'sla@gooddata.com', :subject => "SLA Monitor - Status message", :body => body ) if (!body.empty? and body != "")
    end

    def mail_incident
      body = ""
      @events.each do |e|
        pp e.notified
        pp e
        if (e.severity > Severity.MEDIUM and e.notified == false)
          #stage_schedule = @schedule_in_stage.find{|s| s.r_project == e.key.project_pid and s.graph_name = e.graph and s.mode == e.mode}
          schedule = @schedules.find {|s| s.id.to_s == e.key.value.to_s and e.key.type == "SCHEDULE"}
          e.notified = true
          body << "---------------------------------------- \n"
          body << "Project Pid: #{schedule.project.project_pid} Project Name: #{schedule.project.name} Server: #{schedule.settings_server.name} \n"
          body << "Graph: #{schedule.graph_name} Mode: #{schedule.mode} \n"
          body << e.to_s
          body << "---------------------------------------- \n"
        end
      end
      Pony.mail(:to => "clover@gooddata.pagerduty.com",:from => 'sla@gooddata.com', :subject => "SLA Monitor - PagerDuty incident", :body => body ) if (!body.empty? and body != "")
    end

    private

    def load_events_from_database
      events = EventLog.select("*")
      events.each do |db_event|
        key = Key.new(db_event.key,db_event.event_entity)
        custom_event = CustomEvent.new(key,db_event.severity,db_event.event_type,db_event.text,db_event.created_date,db_event.persistent,true,db_event.notified)
        push_event(custom_event)
      end

      project_category_id = SLAWatcher::Settings.load_project_category_id.first.value
      task_category_id = SLAWatcher::Settings.load_schedule_category_id.first.value

      @schedules = SLAWatcher::Schedule.includes(:project).includes(:project => :project_detail).includes(:settings_server)

      #Post.joins(comments: :guest)

      #@schedule_in_stage = SLAWatcher::StageTask.task_by_category(task_category_id)

    end




  end

end