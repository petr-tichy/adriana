module SLAWatcher
  class Project < ActiveRecord::Base
    self.table_name = 'log2.project'

    def self.load_(status)
      where("status = ?", status)
    end

    def self.load_projects()
      find_by_sql(
          "SELECT DISTINCT p.project_pid FROM log2.project p
            INNER JOIN log2.schedule s On p.project_pid = s.r_project
            WHERE s.server = 'CloudConnect' AND p.status = 'Live'")
    end


  end
end