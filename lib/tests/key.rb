module SLAWatcher
  class Key

    attr_accessor :value,:type

    def initialize(value,type)
      @value = value
      @type = type
    end


    def to_s
      "Value: #{@value} Type: #{@type}"
    end

  end
end