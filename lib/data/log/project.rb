module SLAWatcher
  class Project < ActiveRecord::Base
    attr_accessible :project_pid

    self.table_name = 'log2.project'
    self.primary_keys = :project_pid

    def self.load_(status)
      where("status = ?", status)
    end


    def self.load_projects()
      find_by_sql(
          "SELECT DISTINCT p.project_pid FROM log2.project p
            INNER JOIN log2.schedule s On p.project_pid = s.r_project
            INNER JOIN log2.settings_server ss ON ss.id = s.settings_server_id
            WHERE ss.server_type = 'cloudconnect' AND p.status = 'Live'")
    end

    def self.load_deleted_projects()
      where("is_deleted = ? and p.contract_id IS NULL", "false")
    end



  end
end