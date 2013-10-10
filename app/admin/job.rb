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
    if (job.job_type.key == "restart")
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
    end
  end


  #member_action :comments do
  #  @post = Post.find(params[:id])

    # This will render app/views/admin/posts/comments.html.erb
  #end

  controller do
    include ApplicationHelper
    def new
      if (params["type"] == "restart")
        job_type = JobType.find_by_key(params["type"])
        @job = Job.new(:job_type_id => job_type.id,:recurrent => false,:scheduled_at => DateTime.now)
        @entities = []
        @selection = []
        schedules = Schedule.with_project.find(params["selection"])
        schedules.each do |s|
          job_entity = {:type => "Schedule",:project => s.project_name,:graph_name => s.graph_name,:mode => s.mode,:status => "NEW"}
          @selection.push(s.id)
          @entities.push(job_entity)
        end
      end
    end

    def create
      date = "#{params["job"]["scheduled_at_date"]}T#{params["job"]["scheduled_at_time_hour"]}:#{params["job"]["scheduled_at_time_minute"]}:00"
      schedule_at = DateTime.strptime(date,'%Y-%m-%dT%H:%M:%S')
      selection = params["job"]["selection"].tr('"','').tr('[','').tr(']','')
      schedules = selection.split(",").map {|i| Integer(i) }
      job_type = JobType.find_by_key(params["job"]["key"])
       ActiveRecord::Base.transaction do
         job = Job.create(:job_type_id => job_type.id,:status => "WAITING",:scheduled_by => current_active_admin_user, :recurrent => false,:scheduled_at => schedule_at)
        schedules.each do |e|
           JobEntity.create(:job_id => job.id,:status => "WAITING",:r_schedule => e)
         end
      end
      redirect_to admin_jobs_path,:notice => "Job was create!"
    end
  end


  #form do |f|

    #panel ("SLA") do
   # div :class => "form" do
   #   f.inputs "Info" do
   #     f.input :scheduled_at, :as => :just_datetime_picker
   #     f.input :id
   #   end
   # end
    #end

    #panel ("Contact") do
    #  attributes_table_for project do
    #    [:customer_name, :customer_contact_name, :customer_contact_email,].each do |column|
     #     row column
     #   end
     # end
    #end

   # panel ("Contact") do
   #   if (params["type"] == "restart")
    #    table_for Schedule.with_project.find(params["selection"]) do
    #      column(:type) {"SCHEDULE"}
    #      column(:project_name)
    #      column(:graph_name)
    #      column(:mode)
    #    end
    #  end
    #end


  #end


end