module SLAWatcher

    class CustomEvent

    attr_accessor :key,:severity,:event_type,:text,:created_date,:persistent,:updated_date,:notified,:historical

    def initialize(key,severity,event_type,text,date,persistent,historical = false,notified = false)
      @key = key
      @severity = severity
      @event_type = event_type
      @text = text
      @created_date = date
      @persistent = persistent
      @updated_date = nil
      @notified = notified
      @historical = historical
    end


    def to_s
      "Event " + @key.to_s + "\nSeverity: #{@severity} Type: #{@event_type} Created Date: #{@created_date} Updated Date: #{@updated_date} \nNotified: #{@notified} Persistent: #{@persistent} Type: #{@type}  \n#{@text}\n"
    end

    def to_db_entity
      {:severity => @severity,:event_type => @event_type, :text => @text, :created_date => @created_date, :persistent => @persistent,:notified => @notified,:updated_date => @updated_date,:event_entity => key.type,:key => key.value}
    end



  end

end