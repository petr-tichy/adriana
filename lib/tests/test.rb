module SLAWatcher

  class BaseTest

    attr_accessor :events

    def initialize(events)
      @events = events
    end

    def start
      fail "Not implemented start method"
    end


  end

end