module SLAWatcher
  class Project < ActiveRecord::Base
    set_primary_key = :project_pid
    self.table_name = 'project'


    has_many :running_executions, :through => :schedule
    has_one :project_detail, :primary_key => "project_pid", :foreign_key => "project_pid"
    belongs_to :contract




    def self.load_(status)
      where("status = ?", status)
    end


    def self.load_projects()
      find_by_sql(
          "SELECT DISTINCT p.project_pid FROM project p
            INNER JOIN schedule s On p.project_pid = s.r_project
            INNER JOIN settings_server ss ON ss.id = s.settings_server_id
            WHERE ss.server_type = 'cloudconnect' AND p.status = 'Live'")
    end

    def self.load_deleted_projects()
      where("is_deleted = ? and p.contract_id IS NULL", "false")
    end


    private
    def person_params
      params.permit(:project_pid)
    end



  end
end