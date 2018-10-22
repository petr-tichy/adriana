
module SLAWatcher
  class ProjectInfo < ActiveRecord::Base
    self.table_name = 'project_sheet'
    self.inheritance_column = 'ruby_type'

    def project_type
        self[:type]
    end

    def project_type=(s)
      self[:type] = s
    end

    def next_run
      @next_run
    end

    def next_run=(value)
      @next_run = value
    end


    def self.load_projects(status)
      where("status = ?", status)
    end

  end
end