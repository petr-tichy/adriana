ActiveAdmin.register Schedule do
  filter :r_project
  filter :mode
  filter :main
  filter :settings_server_name, :label => "Server", :as => :select, :collection => proc { (SettingsServer.all).map{|ss| [ss.name, ss.name]} }

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



  form do |f|
    f.inputs "Info" do
      f.input :graph_name
      f.input :mode
      f.input :main
      f.input :settings_server
      f.input :cron
      f.input :r_project,:as => :hidden
      f.input :is_deleted,:as => :hidden
    end
    f.inputs "Detail" do
      f.input :gooddata_schedule
      f.input :gooddata_process
    end
    f.actions
  end


  index do
    selectable_column
    column :project_name
    column "Project PID", :r_project
    column :mode
    column :server do |schedule|
      schedule.settings_server.name
    end
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
    actions
  end


  show :title => "Schedule" do
    columns do
      column  do
        panel ("Info") do
          attributes_table_for schedule do
            row :project do |s|
              Project.find(s.r_project).name
            end
            row :graph_name
            row :mode
            row :main
            row :settings_server
          end

        end
      end

      column do
        panel ("Detail") do
          attributes_table_for schedule do
            row :gooddata_schedule
            row :gooddata_process
            row :updated_by do |s|
              AdminUser.find(s.updated_by).email
            end
            row :created_at
            row :updated_at
          end
        end
      end
    end

    panel ("Executions") do
      table_for ExecutionLog.get_last_x_executions(10,params["id"]) do
        column :status do |e|
          if (!e["status"].nil?)
            if (e["status"] == "RUNNING")
              status_tag "RUNNING",:warning
            elsif (e["status"] == "FINISHED")
              status_tag "FINISHED",:ok
            else
              status_tag "ERROR",:error
            end
          end
        end
        column :detailed_status
        column :event_start
        column :event_end
        column("Duration") do |e|
          distance_of_time_in_words(e.event_end, e.event_start)
        end
      end
    end




  end


  controller do

    include ApplicationHelper

    def scoped_collection
      Schedule.default
    end

    def update
      schedule = Schedule.where("id = ?",params[:id]).first
      public_attributes = Schedule.get_public_attributes

      ActiveRecord::Base.transaction do
        public_attributes.each do |attr|
          if (!same?(params[:schedule][attr],schedule[attr]))
            ScheduleHistory.add_change(schedule.id,attr,params[:schedule][attr].to_s,current_active_admin_user)
            schedule[attr] = params[:schedule][attr]
          end
        end
        schedule.updated_by = current_active_admin_user.id
        schedule.save
      end
      redirect_to admin_schedule_path(params[:id])
    end

    def destroy
      schedule = Schedule.find(params[:id])
      ActiveRecord::Base.transaction do
        ScheduleHistory.add_change(schedule.id,"is_deleted","true",current_active_admin_user)
        schedule.is_deleted = true
        schedule.updated_by = current_active_admin_user.id
        schedule.save
      end
      redirect_to admin_schedule_path,:notice => "Schedule was deleted!"
    end


  end




end                                   
