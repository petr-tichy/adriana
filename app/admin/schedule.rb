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

  scope :error do |schedule|
    schedule.where("e.status = 'ERROR'")
  end

  scope :running do |schedule|
    schedule.where("e.status = 'RUNNING'")
  end

  scope :finished do |schedule|
    schedule.where("e.status = 'FINISHED'")
  end

  batch_action :restart,:confirm => "Do you want to restart selected schedules?" do |selection|
    redirect_to new_admin_job_path(:type => "restart",:selection => selection)
  end

  index do
    selectable_column
    column :project_name
    column "Project PID", :r_project
    column :mode
    column :server_name
    column :cron
    column :main
    column :status do |schedule|
      if (!schedule["status"].nil?)
        if (schedule["status"] == "RUNNING")
          status_tag "RUNNING",:warning
        elsif (schedule["status"] == "FINISHED")
          status_tag "FINISHED",:ok
        else
          status_tag "ERROR",:error
        end
      end
    end
    column :execution_time do |schedule|
      if (!schedule["status"].nil?)
        if (schedule["status"] == "RUNNING")
          l(DateTime.parse(schedule.event_start),:format => :short)
        else
          l(DateTime.parse(schedule.event_end),:format => :short)
        end
      end
    end


  end

  controller do

    def scoped_collection
      Schedule.default
    end


  end




end                                   
