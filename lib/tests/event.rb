module SLAWatcher

    class CustomEvent

    attr_accessor :key,:severity,:event_type,:text,:created_date,:persistent,:updated_date,:notified,:historical

    def initialize(key,severity,event_type,text,date,persistent,historical = false)
      @key = key
      @severity = severity
      @event_type = event_type
      @text = text
      @created_date = date
      @persistent = persistent
      @updated_date = nil
      @notified = false
      @historical = historical
    end


    def to_s
      "Event " + @key.to_s + "\nSeverity: #{@severity} Type: #{@event_type} Created Date: #{@created_date} Updated Date: #{updated_date} \nNotified: #{notified} Persistent: #{@persistent}  \n#{text}"
    end

    def to_db_entity
      {:project_pid => @key.project_pid,:graph_name => @key.graph,:mode => @key.mode,:severity => @severity,:event_type => @event_type, :text => @text, :created_date => @created_date, :persistent => @persistent,:notified => @notified,:updated_date => @updated_date}
    end



  end

end