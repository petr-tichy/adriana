require 'pony'

# This job takes collected events from ran tests and sends alerts to PagerDuty according to rules in #should_alert_pd?
module TestJob
  class Events
    def initialize(events, pd_service, pd_entity)
      load_data_from_db
      @events = events
      @pd_service = pd_service
      @pd_entity = pd_entity
    end

    def pd_service(test = false)
      @pd_service[test ? :l2 : :ms]
    end

    def save
      # 1) Create contract grouping - per contract ID, add all corresponding schedules from collected events
      contract_events_grouping = create_contract_grouping

      # 2) Handle events that have a schedule (with contract grouping)
      # For ERROR_TEST events, one PD alert PER CONTRACT is sent with all the messages collected,
      #   but for each schedule-event pair, a NotificationLog record is created/updated
      # For events other than ERROR_TEST, PD alert is sent for each one (that has the :trigger_pd_event flag set - severity must be >2 etc),
      contract_events_grouping.each_value do |events|
        # Reject muted schedules, this also checks on project and contract
        events = events.reject { |e| e[:schedule].muted? }

        # Collect error messages from all events per contract and set flag :trigger_pd_event if an event should be sent
        common_subject = fill_messages_for_events(events)
        flag_pd_triggers_for_events(events)

        # Create PD alert for ERROR_TEST events - one per contract
        common_messages = events.select { |e| e[:event].key.type == 'ERROR_TEST' && e[:trigger_pd_event] }.map { |e| e[:message] }
        pd_event_id = common_messages.any? ? create_pd_events_by_group(common_subject, common_messages) : nil

        # Create notification logs for ERROR_TEST events
        error_test_events = events.find_all { |e| e[:event].key.type == 'ERROR_TEST' }
        error_test_events.each do |value|
          if value[:event].notification_id.nil?
            value[:event].pd_event_id = pd_event_id if value[:trigger_pd_event]
            NotificationLog.create!(value[:event].to_db_entity(common_subject, value[:message].to_s))
          else
            value[:old_event].update(value[:event].to_db_entity(common_subject, value[:message].to_s))
          end
        end

        # Create notification logs and PD alert for events other than ERROR_TEST
        non_error_test_events = events.find_all { |e| e[:event].key.type != 'ERROR_TEST' }
        non_error_test_events.each do |value|
          message = value[:message]
          subject = "#{value[:schedule].contract.name} - #{value[:event].key.type}"
          if value[:trigger_pd_event]
            pd_service_id = pd_service(value[:schedule].settings_server.server_type == 'cloudconnect')
            pd_event = create_pd_event(pd_service_id, subject, message)
            value[:event].pd_event_id = pd_event['incident_key']
          end
          event_db_entity = value[:event].to_db_entity(subject, message.to_s)
          if value[:event].notification_id.nil?
            NotificationLog.create!(event_db_entity)
          else
            value[:old_event].update(event_db_entity)
          end
        end
      end

      # 3) Handle events that don't have a schedule
      @events.find_all { |e| e.schedule_id.nil? }.each do |e|
        subject = "#{e.key.value} - #{e.key.type}"
        message = {'text' => e.text}

        event_notification_id = e.notification_id
        notification_log = NotificationLog.find_by_id(event_notification_id) unless event_notification_id.nil?
        if should_alert_pd?(e, notification_log, event_notification_id)
          pd_event = create_pd_event(pd_service, subject, message)
          e.pd_event_id = pd_event['incident_key']
        end
        event_db_entity = e.to_db_entity(subject, message.to_s)
        event_notification_id.nil? ? NotificationLog.create!(event_db_entity) : notification_log.update(event_db_entity)
      end
    end

    def create_pd_event(pd_service, subject, message)
      @pd_entity.Incident.create(pd_service, subject, nil, nil, nil, message)
    end

    # Group events with schedules by contract, add references to schedules
    def create_contract_grouping
      contract_grouping = {}
      @events.reject { |e| e.schedule_id.nil? }.each do |event|
        schedule = @schedules.find { |sch| sch.id == event.schedule_id }
        schedules_list = []
        if contract_grouping.key?(schedule.contract.id)
          schedules_list = contract_grouping[schedule.contract.id]
        else
          contract_grouping[schedule.contract.id] = schedules_list
        end
        schedules_list << {:schedule => schedule, :event => event}
      end
      contract_grouping
    end

    def create_pd_events_by_group(subject, messages)
      pd_service_id = pd_service(messages.all? { |x| x.key?('console_link') })
      pd_event = nil
      3.times do
        pd_event = create_pd_event(pd_service_id, subject, messages)
        break unless pd_event.nil?
        sleep 3
      end
      if pd_event.nil?
        pd_event = create_pd_event(pd_service, subject, "ERROR TEST event not accepted by PagerDuty. First message: #{messages[0]}")
      end
      pd_event['incident_key'].tap { |x| raise 'No PD incident_key returned even after custom error message.' if x.nil? }
    rescue StandardError => e
      raise "Unable to create PD alert. Subject: #{subject}, Messages: #{messages}, Error: #{e.message}"
    end

    # @return [String] Common subject for a group of events
    def fill_messages_for_events(events)
      common_subject = nil
      events.each do |event|
        common_subject ||= "#{event[:schedule].contract.name} - ERROR_TEST"
        event[:message] = compose_message(event)
      end
      common_subject || ''
    end

    def flag_pd_triggers_for_events(events)
      events.each do |value|
        event_notification_id = value[:event].notification_id
        value[:old_event] = NotificationLog.find_by_id(event_notification_id) unless event_notification_id.nil?
        value[:trigger_pd_event] = should_alert_pd?(value[:event], value[:old_event], event_notification_id)
      end
    end

    def should_alert_pd?(event, old_event, event_notification_id)
      event.severity > Severity.MEDIUM && (event_notification_id.nil? || (!event_notification_id.nil? && event.severity > old_event.severity))
    end

    # This is the message that gets sent to PagerDuty as description
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

    private

    def load_data_from_db
      @schedules = Schedule.joins(:project).joins(:settings_server).joins(:contract).joins(:customer)
    end
  end
end
