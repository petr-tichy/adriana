ActiveAdmin.register Job do
  form :partial => 'form'


  index do
    column :job_type
    column :scheduled_at
    column :started_at
    column :finished_at
    column :scheduled_by do |job|
      AdminUser.find(job.scheduled_by).email
    end
    column :recurrent
    column :status
    column :detail do |job|
      link_to "Detail", :controller => "jobs", :action => "show",:id => job.id
    end
  end


  show do |at|
    job = Job.joins(:job_type).find(params["id"])

    panel ("Detail") do
      attributes_table_for job do
        row :job_type
        row :scheduled_at
        row :started_at
        row :finished_at
        row :scheduled_by do |job|
          AdminUser.find(job.scheduled_by).email
        end
        row :recurrent
        row :status do |job|
          if (job.status == "WAITING")
            status_tag "WAITING",:warning
          elsif (job.status == "FINISHED" or job.status == "RUNNING")
            status_tag job.status,:ok
          else
            status_tag "ERROR",:error
          end
        end
      end
    end
      if (job.job_type.key == "restart")
        panel ("") do
          table_for JobEntity.get_job_entities_schedule(params["id"]) do
            column(:project_name)
            column(:graph_name)
            column(:mode)
            column(:status) do |job_entity|
              value = job_entity.status
              if (value == "WAITING")
                status_tag value,:warning
              elsif (value == "FINISHED" or value == "RUNNING")
                status_tag value,:ok
              else
                status_tag value,:error
              end
            end
          end
        end
      elsif(job.job_type.key == "synchronize_customer")
        panel ("Customer") do
          attributes_table_for Customer.customer_by_job_id(params["id"]) do
            row :name
            row :contact_email
            row :contact_person
          end
        end
        panel ("Setting Parameters") do
          table_for JobParameter.where("job_id = ?",params["id"]) do
            column(:key)
            column(:value)
          end
        end
      end
    end



  controller do
    layout 'active_admin',  :only => [:new]
    include ApplicationHelper

    def new
      if (params["type"] == "restart")
        job_type = JobType.find_by_key(params["type"])
        @job = Job.new(:job_type_id => job_type.id,:recurrent => false,:scheduled_at => DateTime.now)
        @entities = []
        selection_array = []
        schedules = Schedule.with_project.find(params["selection"])
        schedules.each do |s|
          job_entity = {:type => "Schedule",:project => s.project_name,:graph_name => s.graph_name,:mode => s.mode,:status => "NEW"}
          selection_array.push(s.id)
          @entities.push(job_entity)
        end
        @selection = selection_array.join(",")
        render "restart_job"
      elsif (params["type"] == "synchronize_customer")
        job_type = JobType.find_by_key(params["type"])
        @job = Job.new(:job_type_id => job_type.id,:recurrent => false,:scheduled_at => DateTime.now)
        @customer = params["customer"]
        @parameters = []
        @parameters.push({"name" => "param_mode","setting" => {:as => :string,:label => "Mode"}})
        render "synchronize_customer_job"
      end
    end

    def create
      if (params.key?("job"))
        date = "#{params["job"]["scheduled_at_date"]}T#{params["job"]["scheduled_at_time_hour"]}:#{params["job"]["scheduled_at_time_minute"]}:00"
        schedule_at = DateTime.strptime(date,'%Y-%m-%dT%H:%M:%S')
        schedules = params["job"]["selection"].split(",")
        job_type = JobType.find_by_key(params["job"]["key"])
         ActiveRecord::Base.transaction do
           job = Job.create(:job_type_id => job_type.id,:status => "WAITING",:scheduled_by => current_active_admin_user, :recurrent => false,:scheduled_at => schedule_at)
          schedules.each do |e|
             JobEntity.create(:job_id => job.id,:status => "WAITING",:r_schedule => e)
           end
         end
        redirect_to admin_jobs_path,:notice => "Job was create!"
      elsif (params.key?("jobs") and params["jobs"]["key"] == "synchronize_customer" )
        # Parameters initialization
        date = "#{params["jobs"]["scheduled_at_date"]}T#{params["jobs"]["scheduled_at_time_hour"]}:#{params["jobs"]["scheduled_at_time_minute"]}:00"
        schedule_at = DateTime.strptime(date,'%Y-%m-%dT%H:%M:%S')
        customer = params["jobs"]["customer"]
        recurrent = params["jobs"]["recurrent"]
        job_type = JobType.find_by_key(params["jobs"]["key"])

        parameters = []
        params["jobs"].each_pair do | key, value |
          if (key.include?("param_"))
            parameters.push(:key => key.gsub("param_","") ,:value => value)
          end
        end
        #DB Save
        ActiveRecord::Base.transaction do
          job = Job.create(:job_type_id => job_type.id,:status => "WAITING",:scheduled_by => current_active_admin_user, :recurrent => recurrent,:scheduled_at => schedule_at)
          JobEntity.create(:job_id => job.id,:status => "WAITING",:r_customer => customer)
          parameters.each do |p|
            JobParameter.create(:job_id => job.id,:key => p[:key],:value => p[:value])
          end
        end
        redirect_to admin_jobs_path,:notice => "Job was create!"
      end
    end
  end


end