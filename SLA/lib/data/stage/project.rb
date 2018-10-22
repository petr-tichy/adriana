module SLAWatcher
  class StageProject < ActiveRecord::Base
    self.table_name = 'stage.project'


    def self.project_by_category(category)
      select('project.de_project_pid,project.de_operational_status,project.name,u.emailaddr as email, project.de_solution_engineer as ms_person,project.de_running_on as server,project.de_sla___enabled as sla_enabled, project.de_sla___type as sla_type, project.de_sla___value as sla_value,project.de_customer_name as de_customer_name,project.de_customer_contact_name as de_customer_contact_name,project.de_customer_contact_email as de_customer_contact_email').joins('LEFT OUTER JOIN stage.user u ON u.id = project.ownerid').where("project.categoryid = ? and project.de_project_pid != ''",category)
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