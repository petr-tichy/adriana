require 'pony'

module TestJob
  class Events
    def initialize(events, pd_service, pd_entity)
      load_data_from_database
      @events = events
      @pd_service = pd_service
      @pd_entity = pd_entity
    end

    def find_event_index(event)
      @events.index { |e| e.key.type == event.key.type && e.key.value.to_s == event.key.value.to_s && e.event_type == event.event_type }
    end

    def find_events_by_type(type)
      @events.find_all { |e| e.event_type == type }
    end

    def pd_service(test = false)
      @pd_service[test ? :l2 : :ms]
    end

    # TODO: could use some refactoring
    def save
      # Here we are saving the data about notifications to DB and creating PD event
      # There are several sections of code here
      # Section 1 is for events with schedule_id (error_test,finished_test)
      # We are distigusining here if the event is from ERROR_TEST or from somewhere else
      # For ERROR_TEST we are doing grouping of events by contract. Error will be grouped by CONTRACT.
      # The ERROR will be save to DB normally, byt only one PD event is created in Pagerduty
      # The section 2 is for events without schedule_id.
      # The Errors for this section are created normally.

      # Create contract grouping - per contract ID, add all corresponding schedules from events
      contract_grouping = {}
      @events.each do |e|
        next if e.schedule_id.nil?
        s = @schedules.find { |s| s.id == e.schedule_id }
        schedules_list = []
        if !contract_grouping.key?(s.contract.id)
          contract_grouping[s.contract.id] = schedules_list
        else
          schedules_list = contract_grouping[s.contract.id]
        end
        schedules_list << {:schedule => s, :event => e}
      end

      # Handle events that have a schedule (with contract grouping)
      contract_grouping.each_value do |events|
        messages = []
        subject = ''
        events.each do |value|
          next if value[:schedule].muted?
          # Compose message
          subject = "#{value[:schedule].contract.name} - ERROR_TEST"
          message = compose_message(value)
          value[:message] = message
          value[:pd_event] = false

          # Include message according to rules
          event_notification_id = value[:event].notification_id
          value[:old_event] = NotificationLog.find_by_id(event_notification_id) unless event_notification_id.nil?
          if value[:event].severity > Severity.MEDIUM && (event_notification_id.nil? || (!event_notification_id.nil? && value[:event].severity > value[:old_event].severity))
            messages << message if value[:event].key.type == 'ERROR_TEST'
            value[:pd_event] = true
          end
        end

        # Create PD event - one per contract
        pd_event = nil
        if messages.any?
          pd_service_id = pd_service(messages.all? { |x| x.key?('console_link') })
          3.times do
            pd_event = create_pd_event(pd_service_id, subject, messages)
            break unless pd_event.nil?
            sleep 3
          end
          if pd_event.nil?
            pd_event = create_pd_event(pd_service, subject, "ERROR TEST event not accepted by PagerDuty. First message: #{messages[0]}")
          end
          pd_event_id = pd_event['incident_key']
        end

        # Create notifications for ERROR_TEST events
        error_test_events = events.find_all { |e| e[:event].key.type == 'ERROR_TEST' }
        error_test_events.each do |value|
          if value[:event].notification_id.nil?
            value[:event].pd_event_id = pd_event_id if value[:pd_event]
            NotificationLog.create!(value[:event].to_db_entity(subject, value[:message].to_s))
          else
            value[:old_event].update(value[:event].to_db_entity(subject, value[:message].to_s))
          end
        end

        # Create notifications and PD incident for events other than ERROR_TEST
        non_error_test_events = events.find_all { |e| e[:event].key.type != 'ERROR_TEST' }
        non_error_test_events.each do |value|
          message = value[:message]
          subject = "#{value[:schedule].contract.name} - #{value[:event].key.type}"
          if value[:pd_event]
            pd_service_id = pd_service(value[:schedule].settings_server.server_type == 'cloudconnect')
            pd_event = create_pd_event(pd_service_id, subject, message)
            value[:event].pd_event_id = pd_event['incident_key']
          end
          event_db_entity = value[:event].to_db_entity(subject, message.to_s)
          value[:event].notification_id.nil? ? NotificationLog.create!(event_db_entity) : value[:old_event].update(event_db_entity)
        end
      end

      # Handle events that don't have a schedule
      @events.find_all { |e| e.schedule_id.nil? }.each do |e|
        subject = "#{e.key.value} - #{e.key.type}"
        message = {'text' => e.text}

        event_notification_id = e.notification_id
        notification_log = NotificationLog.find_by_id(event_notification_id) unless event_notification_id.nil?
        if e.severity > Severity.MEDIUM && (event_notification_id.nil? || (!event_notification_id.nil? && e.severity > notification_log.severity))
          pd_event = create_pd_event(pd_service, subject, message)
          e.pd_event_id = pd_event['incident_key']
        end
        event_db_entity = e.to_db_entity(subject, message.to_s)
        event_notification_id.nil? ? NotificationLog.create!(event_db_entity) : notification_log.update(event_db_entity)
      end
    end

    def compose_message(event_value)
      value = event_value
      message = {'event_type' => value[:event].key.type,
                 'project_name' => value[:schedule].project.name,
                 'schedule_graph' => value[:schedule].graph_name,
                 'schedule_mode' => value[:schedule].mode}
      if value[:schedule].settings_server.server_type == 'cloudconnect'
        message.merge!('console_link' => "#{value[:schedule].settings_server.server_url}/admin/disc/#/projects/#{value[:schedule].r_project}/processes/#{value[:schedule].gooddata_process}/schedules/#{value[:schedule].gooddata_schedule}")
      end
      message.merge!('text' => value[:event].text)
      message.merge!('log' => value[:event].log) unless value[:event].log.nil?
      message
    end

    def create_pd_event(pd_service, subject, message)
      @pd_entity.Incident.create(pd_service, subject, nil, nil, nil, message)
    end

    def mail_incident
      body = ''
      @events.each do |e|
        pp e
        next unless e.severity > Severity.MEDIUM && e.notified == false
        #stage_schedule = @schedule_in_stage.find{|s| s.r_project == e.key.project_pid and s.graph_name = e.graph and s.mode == e.mode}
        schedule = @schedules.find { |s| s.id.to_s == e.key.value.to_s && e.key.type == 'SCHEDULE' }
        e.notified = true
        body << "---------------------------------------- \n"
        body << "Project Pid: #{schedule.project.project_pid} Project Name: #{schedule.project.name} Server: #{schedule.settings_server.name} \n"
        body << "Graph: #{schedule.graph_name} Mode: #{schedule.mode} \n"
        body << e.to_s
        body << "---------------------------------------- \n"
      end
      unless body.empty?
        Pony.mail(:to => 'clover@gooddata.pagerduty.com', :from => 'sla@gooddata.com', :subject => 'SLA Monitor - PagerDuty incident', :body => body)
      end
    end

    private

    def load_data_from_database
      # project_category_id = SLAWatcher::Settings.load_project_category_id.first.value
      # task_category_id = SLAWatcher::Settings.load_schedule_category_id.first.value
      @schedules = Schedule.joins(:project).joins(:settings_server).joins(:contract).joins(:customer)
      #@schedules = SLAWatcher::Schedule.includes(:project,:contract,:settings_server).joins(:contract).includes(:settings_server)
    end
  end
end
