module SLAWatcher
  class StageProject < ActiveRecord::Base
    self.table_name = 'stage.project'


    def self.project_by_category(category)
      select('project.de_project_pid,project.de_operational_status,project.name,u.emailaddr as email, project.de_solution_engineer as ms_person').joins('LEFT OUTER JOIN stage.user u ON u.id = project.ownerid').where("project.categoryid = ? and project.de_project_pid != ''",category)
    end

    #def self.project_users
    #  joins('LEFT OUTER JOIN stage.user u ON u.id = project.ownerid').where("categoryid = ? ","kokos")
    #end

    #lambda{{
    #:select => "project.*",
    #:conditions => ["project.categoryid = ?","kosos"],
    #:joins => ["LEFT OUTER JOIN stage.user u ON u.id = project.ownerid"]
    #}}


    #named_scope :recently_commented, lambda {{
    #    :select => "project.*",
    #    :joins => "LEFT JOIN stage.user ON user.id = project.ownerid"
    #    #,:conditions => ["last_comment_datetime > ?", 24.hours.ago]
    #}}





  end
end