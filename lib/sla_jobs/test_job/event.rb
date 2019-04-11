module TestJob
  class CustomEvent

    attr_accessor :key, :severity, :event_type, :text, :created_date, :pd_event_id, :notification_id, :schedule_id, :log

    def initialize(key, severity, text, date, pd_event_id, schedule_id, notification_id = nil, log = nil)
      @key = key
      @severity = severity
      @text = text
      @created_date = date
      @pd_event_id = pd_event_id
      @notification_id = notification_id
      @schedule_id = schedule_id
      @log = log
    end

    def to_s
      'Event ' + @key.to_s + "\nSeverity: #{@severity} Type: #{@event_type} Created Date: #{@created_date} Schedule Id: #{@schedule_id} Notification Id: #{@notification_id} \n#{@text}\n"
    end

    def to_db_entity(subject, message)
      entity = {
        :key => @key.value,
        :notification_type => @key.type,
        :severity => @severity,
        :subject => subject,
        :message => message
      }
      entity[:pd_event_id] = @pd_event_id unless @pd_event_id.to_s.empty?
      entity
    end
  end
end