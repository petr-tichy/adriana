module SLAWatcher

  class CustomEvent

    attr_accessor :key,:severity,:type,:text,:date,:persistent

    def initialize(key,severity,type,text,date,persistent,project_name,server)
      @key = key
      @severity = severity
      @type = type
      @text = text
      @date = date
      @persistent = persistent
      @project_name = project_name
      @server = server
    end


    def to_s
      "Event " + @key.to_s + "\n Project Name: #{@project_name} Server: #{@server} \nSeverity: #{@severity} Type: #{@type} Date: #{@date} Persistent: #{@persistent} \n#{text}"
    end

  end

end