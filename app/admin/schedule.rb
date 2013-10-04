ActiveAdmin.register Schedule do

  filter :r_project
  filter :mode
  filter :server
  filter :main

  scope :all, :default => true
  scope :cloudconnect do |schedule|
    schedule.where("server = ?","CloudConnect")
  end
  scope :clover_prod do |schedule|
    schedule.where("server IN ('clover-prod2','clover-prod3')")
  end
  scope :clover_dev do |schedule|
    schedule.where("server IN ('clover-dev2')")
  end

  index do
    executions = Schedule.get_last_executions
    projects = Project.select("*")

    column :project_name do |schedule|
      project = projects.find{|p| p.project_pid == schedule.r_project}
      if (!project.nil?)
        project.name
      end
    end
    column "Project PID", :r_project
    column :mode
    column :server
    column :cron
    column :main
    column :status do |schedule|
      execution = executions.find{|e| e.id == schedule.id}
      if (!execution.nil?)
        if (execution["status"] == "RUNNING")
          status_tag "RUNNING",:warning
        elsif (execution["status"] == "FINISHED")
          status_tag "FINISHED",:ok
        else
          status_tag "ERROR",:error
        end
      end
    end
    column :execution_time do |schedule|
      execution = executions.find{|e| e.id == schedule.id}
      if (!execution.nil?)
        if (execution["status"] == "RUNNING")
          l(DateTime.parse(execution.event_start),:format => :short)
        else
          l(DateTime.parse(execution.event_end),:format => :short)
        end
      end
    end


  end

  controller do
    before_filter :only => [:index] do
      if params['commit'].blank?
        params['q'].merge!({:is_deleted_eq => '0'}) if !params['q'].nil?
      end
    end

  end


end                                   
