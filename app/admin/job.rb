ActiveAdmin.register Job do
  form :partial => 'form'


  index do
    column :job_type
    column :entity do |job|
      if (job.job_type.key ==  'synchronize_contract')
        entity = JobEntity.find_by_job_id(job.id)
        link_to "Contract", :controller => "contracts", :action => "show",:id => entity.r_contract
      end
    end
    column :scheduled_by do |job|
      AdminUser.find(job.scheduled_by).email
    end
    column :scheduling do |job|
      if (job.recurrent)
         job.cron
      else
         job.scheduled_at
      end
    end

    column :started_at
    column :finished_at
    column :status do |job|
      value = job.status
      if (value == "WAITING")
        status_tag value,:warning
      elsif (value == "FINISHED" or value == "RUNNING")
        status_tag value,:ok
      else
        status_tag value,:error
      end
    end
    column :log do |job|
      if (!job.job_history_id.nil?)
        link_to "Log", :controller => "jobs", :action => "job_history_log",:id => job.job_history_id, :target => '_blank'
      end

    end
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
        row :scheduled_by do |job|
          AdminUser.find(job.scheduled_by).email
        end
        row :recurrent
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
              if (value == "WAITING" or value == "RUNNING")
                status_tag value,:warning
              elsif (value == "FINISHED" or value == "DONE")
                status_tag value,:ok
              else
                status_tag value,:error
              end
            end
          end
        end
      elsif(job.job_type.key == "synchronize_contract")
        panel ("Contract") do
          attributes_table_for Contract.contract_by_job_id(params["id"]) do
            row :name
          end
        end
        panel ("Setting Parameters") do
          table_for JobParameter.where("job_id = ?",params["id"]) do
            column(:key)
            column(:value)
          end
        end

        panel ("Job History") do
          table_for JobHistory.where("job_id = ?",params["id"]).order("started_at DESC").limit(10) do
            column(:status) do |job_history|
              value = job_history.status
              if (value == "WAITING")
                status_tag value,:warning
              elsif (value == "FINISHED" or value == "RUNNING")
                status_tag value,:ok
              else
                status_tag value,:error
              end
            end
            column(:started_at)
            column(:finished_at)
            column(:log) do |job_history|
              link_to "Log", :controller => "jobs", :action => "job_history_log",:id => job_history.id, :target => '_blank'
            end

          end
        end

      end
    end



  member_action :job_history_log do
    @log = JobHistory.find(params[:id]).log
    # This will render app/views/admin/posts/comments.html.erb
  end


  controller do
    layout 'active_admin',  :only => [:new]
    include ApplicationHelper

    def scoped_collection
      Job.default
    end

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
      elsif (params["type"] == "synchronize_contract")
        job_type = JobType.find_by_key(params["type"])
        @job = SynchronizationJob.new(:job_type_id => job_type.id,:recurrent => "false",:scheduled_at => DateTime.now)
        #@jobs = CustomJobSynchronization.new({:job_type_id => job_type.id,:recurrent => "false",:scheduled_at => DateTime.now})
        #@jobs = OpenStruct.new(:job_type_id => job_type.id,:recurrent => false,:scheduled_at => DateTime.now)

        @contract = params["contract"]
        @parameters = []
        @parameters.push({"name" => "param_mode","setting" => {:as => :string,:label => "Mode"}})
        @parameters.push({"name" => "param_resource","setting" => {:as => :string,:label => "Resource"}})
        render "synchronize_contract_job"
      end
    end

    def create

      if (params.key?("job"))
        date = "#{params["job"]["scheduled_at_date"]}T#{params["job"]["scheduled_at_time_hour"]}:#{params["job"]["scheduled_at_time_minute"]}:00"
        schedule_at = DateTime.strptime(date,'%Y-%m-%dT%H:%M:%S')
        schedules = params["job"]["selection"].split(",")
        job_type = JobType.find_by_key(params["job"]["key"])
         ActiveRecord::Base.transaction do
           job = Job.create(:job_type_id => job_type.id,:scheduled_by => current_active_admin_user, :recurrent => false,:scheduled_at => schedule_at)
          schedules.each do |e|
             JobEntity.create(:job_id => job.id,:status => "WAITING",:r_schedule => e)
           end
         end
        redirect_to admin_jobs_path,:notice => "Job was create!"
      elsif (params.key?("synchronization_job") and params["synchronization_job"]["key"] == "synchronize_contract" )
        # Parameters initialization
        date = "#{params["synchronization_job"]["scheduled_at_date"]}T#{params["synchronization_job"]["scheduled_at_time_hour"]}:#{params["synchronization_job"]["scheduled_at_time_minute"]}:00"
        schedule_at = DateTime.strptime(date,'%Y-%m-%dT%H:%M:%S')
        contract = params["synchronization_job"]["contract"]
        recurrent = params["synchronization_job"]["recurrent"]
        job_type = JobType.find_by_key(params["synchronization_job"]["key"])
        cron = params["synchronization_job"]["cron"]


        parameters = []
        params["synchronization_job"].each_pair do | key, value |
          if (key.include?("param_"))
            parameters.push(:key => key.gsub("param_","") ,:value => value)
          end
        end
        #DB Save
        # scheduled_at - converting to UTC
        ActiveRecord::Base.transaction do
          job = Job.create(:job_type_id => job_type.id,:scheduled_by => current_active_admin_user, :recurrent => recurrent,:scheduled_at => schedule_at.utc,:cron => cron)
          JobEntity.create(:job_id => job.id,:status => "WAITING",:r_contract => contract,:r_settings_server => params["synchronization_job"]["settings_server_id"] )
          parameters.each do |p|
            JobParameter.create(:job_id => job.id,:key => p[:key],:value => p[:value])
          end
        end
        redirect_to admin_jobs_path,:notice => "Job was create!"
      end
    end
  end


end