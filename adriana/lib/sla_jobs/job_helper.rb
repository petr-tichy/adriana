require 'whedon'

module JobHelper
  class << self
    def get_job_by_name(name)
      job_class = Job::REGISTERED_JOBS[name.to_s.to_sym]
      job_class.tap { |x| fail "The specified job '#{name}' is not available." if x.nil? }
    end

    def interval_to_double(interval)
      temp = interval.split('.')[0].split(':')
      temp[0].to_i * 3600 + temp[1].to_i * 60 + temp[2].to_i
    end

    def value_to_datetime(value)
      DateTime.strptime(value, '%Y-%m-%d %H:%M:%S%z')
    end

    def datetime_to_value(value)
      value.strftime('%Y-%m-%d %H:%M:%S%z')
    end

    def extract_graph_name(graph_name)
      graph_name.match('[^\/]*$')[0].downcase
    end

    def downcase(value)
      return nil if value.nil?
      value.downcase
    end

    def extract_mode(mode)
      return nil if mode == 'UNKNOWN'
      mode.downcase
    end

    def validate_cron(cron_list)
      list = cron_list.split('|')
      output = []
      list.each do |cron|
        begin
          source_length = cron.split(/\s+/).length
          if source_length >= 5 && source_length <= 6
            output.push(:value => cron, :valid => true)
          else
            output.push(:value => cron, :valid => false)
          end
        rescue
          output.push(:value => cron, :valid => false)
        end
      end
      output
    end

    def next_run(cron_list, start_time, time_zone = nil)
      list = cron_list.split('|')
      output = []
      list.each do |cron|
        cron = [cron, time_zone].join(' ') if time_zone
        cron_parser = Whedon::Schedule.new(cron)
        next_run = cron_parser.next(start_time)
        output.push(next_run)
      end
      # Find nearest execution
      output.sort { |a, b| a - start_time <=> b - start_time }
      output.first
    end

    def retryable
      tries ||= 3
      yield
    rescue => e
      if tries -= 1 > 0
        $log.warn "There was error during operation: #{e.message}. Retrying"
        retry
      else
        $log.error e.message
        fail e.message
      end
    end

    def interval_to_minutes(interval)
      days = 0
      if interval =~ /day/
        d = interval.match(/.*day/)[0]
        days = Integer(d.split(' ')[0])
        interval = interval.match(/\d{2}:\d{2}:\d{2}/)[0]
      end

      values = interval.split(':')
      hours = if values[0].chars.to_a[0] == '0'
                Integer(values[0].chars.to_a[1])
              else
                Integer(values[0])
              end

      minutes = if values[1].chars.to_a[0] == '0'
                  Integer(values[1].chars.to_a[1])
                else
                  Integer(values[1])
                end
      days * 24 * 60 + hours * 60 + minutes
    end
  end
end