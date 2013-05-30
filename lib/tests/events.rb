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
      @events.index{|e| e.key.md5 == event.key.md5 and e.event_type == event.event_type}
    end

    def find_event(event)
      @events.find{|e| e.key.md5 == event.key.md5 and e.event_type == event.event_type}
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


    private

    def load_events_from_database
      events = EventLog.select("*")
      events.each do |db_event|
        key = Key.new(db_event.project_pid,db_event.graph_name,db_event.mode)
        custom_event = CustomEvent.new(key,db_event.severity,db_event.event_type,db_event.text,db_event.created_date,db_event.persistent,true)
        push_event(custom_event)
      end
    end




  end

end