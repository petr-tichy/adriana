module SLAWatcher

  class Helper

    def self.interval_to_double(interval)
      temp = interval.split(".")[0].split(":")
      temp[0].to_i * 3600 + temp[1].to_i * 60 + temp[2].to_i
    end

    def self.value_to_datetime(value)
       DateTime.strptime(value,"%Y-%m-%d %H:%M:%S%z")
    end

    def self.datetime_to_value(value)
      value.strftime("%Y-%m-%d %H:%M:%S%z")
    end

    def self.extract_graph_name(graph_name)
      graph_name.match('[^\/]*$')[0]
    end

    def self.extract_mode(mode)
      return nil if mode == 'UNKNOWN'
      return mode
    end




  end
end