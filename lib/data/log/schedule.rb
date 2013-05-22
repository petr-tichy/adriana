module SLAWatcher
  class Schedule < ActiveRecord::Base
    self.table_name = 'log2.schedule'


    def self.load_schedules_of_live_projects
      select("*").joins("INNER JOIN log2.project p ON r_project = p.project_pid").where("p.status = ? and schedule.is_deleted = ?","Live",false)
    end




  end
end