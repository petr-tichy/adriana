module SLAWatcher
  class Key

    attr_accessor :project_pid,:graph,:mode

    def initialize(project_pid,graph = nil,mode = nil)
      @project_pid = project_pid
      @graph = graph
      @mode = mode
    end

    def md5
      Digest::MD5.digest("#{@project_pid}#{@graph}#{@mode}")
    end

    def to_s
      "Project_pid: #{@project_pid}" + (@graph.nil? ? "":" Graph: #{@graph}") + (@mode.nil? ? "":" Mode: #{@mode}")
    end

  end
end