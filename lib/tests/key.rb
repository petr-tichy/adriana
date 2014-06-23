module SLAWatcher
  class Key

    attr_accessor :type


    # Value should be execution_id in most cases
    # In case of start_test it will be id of the schedule
    def initialize(value,type)
      @value = value
      @type = type
    end


    def to_s
      "Value: #{@value} Type: #{@type}"
    end


    def value
      @value.to_s
    end

  end
end