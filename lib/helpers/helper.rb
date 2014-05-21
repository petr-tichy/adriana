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
     graph_name.match('[^\/]*$')[0].downcase
    end


    def self.downcase(value)
      return nil if value.nil?
      value.downcase
    end

    def self.extract_mode(mode)
      return nil if mode == 'UNKNOWN'
      return mode.downcase
    end

    def self.validate_cron(cron_list)
      list = cron_list.split("|")
      output = []
      list.each do |cron|
        begin
          source_length = cron.split(/\s+/).length
          if (source_length >= 5 && source_length <= 6)
            cron_parser = CronParser.new(cron)
            output.push({:value => cron,:valid => true})
          else
            output.push({:value => cron,:valid => false})
          end
        rescue
          output.push({:value => cron,:valid => false})
        end
      end
      output
    end


    def self.next_run(cron_list,time,time_class)
      list = cron_list.split("|")
      output = []
      list.each do |cron|
        cron_parser = CronParser.new(cron,time_class)
        next_run = cron_parser.next(time)
        output.push(next_run)
      end
      #We need to find nearest execution
      output.sort{|a,b| a - time <=> b - time }
      output.first

    end

    def self.retryable
      begin
        tries ||= 3
        yield
      rescue => e
        if (tries -= 1) > 0
          @@log.warn "There was error during operation: #{e.message}. Retrying"
          retry
        else
          @@log.error e.message
          fail e.message
        end
      end
    end

    def self.interval_to_minutes(interval)
      days = 0
      if (interval =~ /day/ )
        d = interval.match(/.*day/)[0]
        days = Integer(d.split(" ")[0])
        interval = interval.match(/\d{2}:\d{2}:\d{2}/)[0]
      end

      values = interval.split(":")
      if (values[0].chars.to_a[0] == "0")
         hours = Integer(values[0].chars.to_a[1])
      else
        hours = Integer(values[0])
      end

      if (values[1].chars.to_a[0] == "0")
        minutes = Integer(values[1].chars.to_a[1])
      else
        minutes = Integer(values[1])
      end
      days*24*60 + hours * 60 + minutes
    end

  end


  class UTCTime < Time

    def now
      Time.now.utc
    end

    def self.local(year,month,day,hour,min,param1)
      # Ok So this looks strange, I know it, but it is working
      Time.local(year,month,day,hour,min,param1).utc + Time.now.gmt_offset
    end



  end

end