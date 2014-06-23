module SLAWatcher

  class Events

    def initialize(events,pd_service,pd_entity)
      load_data_from_database
      @events = events
      @pd_service = pd_service
      @pd_entity = pd_entity
    end

    def find_event_index(event)
      @events.index{|e| e.key.type == event.key.type and e.key.value.to_s == event.key.value.to_s and e.event_type == event.event_type}
    end

    def find_events_by_type(type)
      @events.find_all{|e| e.event_type == type}
    end



    def save
      @events.each do |e|
        subject = ""
        message = ""
        s = @schedules.find{|s| s.id == e.schedule_id}
        if (!s.nil?)
          subject << "#{e.key.type} - #{s.project.name} - #{s.graph_name}"
          message = { "project_name" => s.project.name,
                      "schedule_graph" =>  s.graph_name,
                      "schedule_mode" =>  s.mode}
          message.merge!({"console_link" => "#{s.settings_server.server_url}/admin/disc/#/projects/#{s.r_project}/processes/#{s.gooddata_process}/schedules/#{s.gooddata_schedule}"}) if s.settings_server.server_type == "cloudconnect"
          message.merge!({"text" => e.text})
        else
          subject << "#{e.key.type} - #{e.key.value}"
          message = {"text" => e.text}
        end
        if (e.notification_id.nil?)
          if (e.severity > Severity.MEDIUM)
            pd_event = @pd_entity.Incident.create(@pd_service,subject,nil,nil,nil,message)
            e.pd_event_id = pd_event["incident_key"]
          end
          NotificationLog.create!(e.to_db_entity(subject,message.to_s))
        else
          notification_log = NotificationLog.find_by_id(e.notification_id)
          if (notification_log.severity > e.severity and e.severity > Severity.MEDIUM )
            pd_event = @pd_entity.Incident.create(@pd_service,subject,nil,nil,nil,message)
            e.pd_event_id = pd_event["incident_key"]
          end
          #NotificationLog.update_all(e.to_db_entity(subject,message))
          notification_log.update(e.to_db_entity(subject,message.to_s))
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

    def load_data_from_database
      project_category_id = SLAWatcher::Settings.load_project_category_id.first.value
      task_category_id = SLAWatcher::Settings.load_schedule_category_id.first.value
      @schedules = SLAWatcher::Schedule.joins(:project).joins(:settings_server)

    end




  end

end