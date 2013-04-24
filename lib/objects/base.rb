module SLAWatcher

  class Base

    def initialize()
    end

    def timeline
      @timeline ||= SLAWatcher::Timeline.new()
    end

    def projects
      @projects ||= SLAWatcher::Projects.new()
    end

    def statistics
      @statistics ||= SLAWatcher::Statistics.new()
    end


  end


end