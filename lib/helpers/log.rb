
module SLAWatcher

  class Log
    def initialize
      #@log = Logger.new("log/run.log",'daily')
      @log = Logger.new(STDOUT)
    end

    @@instance = Log.new

    def self.instance
      return @@instance
    end

    def log_error(msg)
      @log.error(msg)
    end

    def log_info(msg)
      @log.info(msg)
    end

    def log_warn(msg)
      @log.warn(msg)
    end


    private_class_method :new
  end
end



