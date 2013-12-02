module SLAWatcher
  class Key

    attr_accessor :type

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