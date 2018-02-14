ActiveAdmin.register_page "Attask Print" do
  menu :priority => 7
  content do
    render :partial => "print_form"
  end


  controller do
    include ApplicationHelper


    def create
      email = params["attask"]["email"]
      job_type = JobType.find_by_key("attask_print_job")
      ActiveRecord::Base.transaction do
        job = Job.new()
        job.scheduled_by = current_active_admin_user.id
        job.job_type_id = job_type.id
        job.recurrent = false
        job.scheduled_at = DateTime.now.utc
        job.save

        job_parameter = JobParameter.new()
        job_parameter.job_id = job.id
        job_parameter.key = "email"
        job_parameter.value = email
        job_parameter.save
      end
      redirect_to admin_attask_print_path, :notice => "Print job created"
    end


  end








end