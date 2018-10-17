module SLAWatcher
  class Execution
    attr_accessor :json

    def initialize(json)
      @json = json
    end

    def id
      json['execution']['links']['self'].split('/').last
    end

    def status
      json['execution']['status']
    end

    def running?
      status == 'RUNNING'
    end

    def ok?
      status == 'OK'
    end

    def error?
      status == 'ERROR'
    end

    def log_uri
      json['execution']['log']
    end

    def start_time
      if json['execution']['startTime'].nil? && !json['execution']['createdTime'].nil?
        DateTime.parse(json['execution']['createdTime'])
      elsif !json['execution']['startTime'].nil?
        DateTime.parse(json['execution']['startTime'])
      else
        puts 'WTF'
        pp json
      end
    end

    alias_method :startTime, :start_time

    def end_time
      if !json['execution']['endTime'].nil?
        DateTime.parse(json['execution']['endTime'])
      else
        # In case that the endTime is not filled in, we are thinking that execution ERRORED right after start ... puthing there createdTime
        DateTime.parse(json['execution']['createdTime'])
      end
    end

    alias_method :endTime, :end_time

  end
end