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
      # In this section of code we are saving the data about notifications to DB and creating PD event
      # There are several sections of code here
      # Section 1 is for events with schedule_id (error_test,finished_test)
      # We are distigusining here if the event is from ERROR_TEST or from somewhere else
      # For ERROR_TEST we are doing grouping of events by contract. Error will be grouped by CONTRACT.
      # The ERROR will be save to DB normally, byt only one PD event is created in Pagerduty
      # The section 2 is for events without schedule_id.
      # The Errors for this section are created normally.
      contract_grouping = {}
      @events.find_all{|e| !e.schedule_id.nil? }.each do |e|
        s = @schedules.find{|s| s.id == e.schedule_id}
        schedules_list = []
        if (!contract_grouping.key?(s.contract.id))
          contract_grouping[s.contract.id] = schedules_list
        else
          schedules_list = contract_grouping[s.contract.id]
        end
        schedules_list << {:schedule => s,:event => e}
      end

      contract_grouping.each_value do |events|
        messages = []
        subject = ""
        events.each do |value|
          subject = "#{value[:schedule].contract.name} - ERROR_TEST"
          message = { "event_type" => value[:event].key.type,
                      "project_name" => value[:schedule].project.name,
                      "schedule_graph" =>  value[:schedule].graph_name,
                      "schedule_mode" =>  value[:schedule].mode}
          message.merge!({"console_link" => "#{value[:schedule].settings_server.server_url}/admin/disc/#/projects/#{value[:schedule].r_project}/processes/#{value[:schedule].gooddata_process}/schedules/#{value[:schedule].gooddata_schedule}"}) if value[:schedule].settings_server.server_type == "cloudconnect"
          message.merge!({"text" => value[:event].text})
          value[:message] = message
          value[:pd_event] = false

          if (value[:event].notification_id.nil?)
            if value[:event].severity > Severity.MEDIUM
              if (value[:event].key.type == "ERROR_TEST")
                messages << message
              end
              value[:pd_event] = true
            end
          else
            notification_log = NotificationLog.find_by_id(value[:event].notification_id)
            value[:old_event] = notification_log
            if (notification_log.severity > value[:event].severity and e.severity > Severity.MEDIUM)
              if (value[:event].key.type == "ERROR_TEST")
                messages << message
              end
              value[:pd_event] = true
            end
          end
        end
        pd_event_id = nil
        if (messages.count > 0)
          pd_event = @pd_entity.Incident.create(@pd_service,subject,nil,nil,nil,messages)
          pd_event_id = pd_event["incident_key"]
        end

        events.find_all{|e| e[:event].key.type == "ERROR_TEST"}.each do |value|
          if (value[:event].notification_id.nil?)
            if (value[:pd_event])
              value[:event].pd_event_id = pd_event_id
            end
            NotificationLog.create!(value[:event].to_db_entity(subject,value[:message].to_s))
          else
            value[:old_event].update(value[:event].to_db_entity(subject,value[:message].to_s))
          end
        end

        events.find_all{|e| e[:event].key.type != "ERROR_TEST"}.each do |value|
          message = value[:message]
          subject = "#{value[:schedule].contract.name} - #{value[:event].key.type}"
          if (value[:event].notification_id.nil?)
            if (value[:pd_event])
              pd_event = @pd_entity.Incident.create(@pd_service,subject,nil,nil,nil,message)
              value[:event].pd_event_id = pd_event["incident_key"]
            end
            NotificationLog.create!(value[:event].to_db_entity(subject,message.to_s))
          else
            value[:old_event].update(value[:event].to_db_entity(subject,message.to_s))
          end

        end
      end

      @events.find_all{|e| e.schedule_id.nil? }.each do |e|
        subject << "#{e.key.value} - #{e.key.type}"
        message = {"text" => e.text}
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
      @schedules = SLAWatcher::Schedule.includes(:project).includes(:settings_server).includes(:contract).includes(:customer => :contract)
      #@schedules = SLAWatcher::Schedule.includes(:project,:contract,:settings_server).joins(:contract).includes(:settings_server)

    end




  end

end