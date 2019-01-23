module SplunkSynchronizationJob
  class SplunkResult
    def initialize(node)
      @result = node
    end

    def time
      @result.dig('_time')
    end

    def raw
      @result.dig('_raw')
    end

    # Defines keys as methods, if available. e.g. splunkResult.sourceIp
    def method_missing(name, *args, &blk)
      if args.empty? && blk.nil? && @result.dig(name.to_s)
        @result.dig(name.to_s)
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      @result.dig(name.to_s).nil? ? super : true
    rescue NoMethodError
      super
    end
  end
end