ActiveAdmin.register Schedule do
  filter :r_project, :label => "Project PID"
  filter :project, :label => "Project Name", :as => :string
  filter :mode
  filter :main
  filter :settings_server_name, :label => "Server", :as => :select, :collection => proc { (SettingsServer.all).map{|ss| [ss.name, ss.name]} }

  filter :contract, :label => "Contract",:as => :select, :collection => Contract.all
  #filter :project_contract_id, :label => "Contract", :as => :select, :collection => proc { (Contract.all).map{|c| [c.id, c.id]} }


  scope :all, :default => true
  scope :direct  do |schedule|
    schedule.where("contract_id IS NULL")
  end

  scope :cloudconnect do |schedule|
    schedule.where("settings_server.server_type = ?","cloudconnect")
  end
  scope :infra do |schedule|
    schedule.where("settings_server.server_type = ?","infra")
  end
  scope :legacy do |schedule|
    schedule.where("settings_server.server_type = ?","bash")
  end

  scope :error do |schedule|
    schedule.where("running_executions.status = 'ERROR'")
  end

  scope :running do |schedule|
    schedule.where("running_executions.status = 'RUNNING'")
  end

  scope :finished do |schedule|
    schedule.where("running_executions.status = 'FINISHED'")
  end

  batch_action :restart,:confirm => "Do you want to restart selected schedules?" do |selection|
    redirect_to new_admin_job_path(:type => "restart",:selection => selection)
  end

  batch_action :destroy, :confirm => "Do you want to delete following schedules?" do |selection|
    schedule = params["collection_selection"]
    schedule.each do |selection|
      ActiveRecord::Base.transaction do
        Schedule.mark_deleted(selection,current_active_admin_user)
      end
    end
    redirect_to admin_schedules_path,:notice => "Schedules were deleted!"
  end

  form  :validate => true do |f|
    f.inputs "Info" do
      f.input :graph_name
      f.input :mode
      f.input :main
      f.input :settings_server
      f.input :cron
      if (params["project_pid"].nil?)
        f.input :r_project,:as => :hidden
      else
        f.input :r_project,:as => :hidden, :input_html => { :value => params["project_pid"] }
      end
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
    column "Project Name" do |schedule|
      schedule.project.name
    end
    column "Project PID" do |schedule|
      link_to schedule.r_project, :controller => "projects", :action => "show",:id => schedule.r_project
    end
    column :mode
    column :server do |schedule|
      schedule.settings_server.name
    end
    column :cron
    column :main
    column :status do |schedule|
      if (!schedule.running_executions.nil? and !schedule.running_executions.status.nil?)
        if (schedule.running_executions.status == "RUNNING")
          status_tag "RUNNING",:warning
        elsif (schedule.running_executions.status == "FINISHED")
          status_tag "FINISHED",:ok
        else
          status_tag "ERROR",:error
        end
      end
    end
    column :execution_time do |schedule|
      if (!schedule.running_executions.nil? and !schedule.running_executions.status.nil?)
        if (schedule.running_executions.status == "RUNNING")
          l(schedule.running_executions.event_start,:format => :short)
        else
          l(schedule.running_executions.event_end,:format => :short)
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
            row :cron
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

    #layout 'active_admin'
    include ApplicationHelper

    def scoped_collection
      Schedule.default
    end

    before_filter :only => [:index] do
      pp params
      if params['commit'].blank?
        params['q'] = {:is_deleted_eq => '0'}
      end
    end

    def update
      schedule = Schedule.where("id = ?",params[:id]).first
      public_attributes = Schedule.get_public_attributes

      params[:schedule]["mode"].downcase! if !params[:schedule]["mode"].nil?
      params[:schedule]["graph_name"].downcase!

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
      ActiveRecord::Base.transaction do
        Schedule.mark_deleted(params[:id],current_active_admin_user)
      end
      redirect_to admin_schedule_path,:notice => "Schedule was deleted!"
    end


    def create
      public_attributes = Schedule.get_public_attributes
      schedule = nil
      ActiveRecord::Base.transaction do
        schedule = Schedule.new()
        schedule.updated_by = current_active_admin_user.id
        schedule.settings_server_id = params[:schedule]["settings_server_id"]
        schedule.r_project = params[:schedule]["r_project"]
        params[:schedule]["mode"].downcase! if !params[:schedule]["mode"].nil?
        params[:schedule]["graph_name"].downcase!
        public_attributes.each do |attr|
          schedule[attr] =  params[:schedule][attr]
        end
        schedule.save
        public_attributes.each do |attr|
          ScheduleHistory.add_change(schedule.id,attr,params[:schedule][attr].to_s,current_active_admin_user)
        end
      end
      redirect_to admin_schedule_path(schedule.id)
    end


  end




end                                   
