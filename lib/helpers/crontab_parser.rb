module SLAWatcher

  class CrontabParser

    def self.next_run(cron,actual_time =  Time.new)
      parser = CronParser.new(cron)
      parser.next(actual_time)
    end
  end
end