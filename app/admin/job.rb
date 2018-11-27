ActiveAdmin.register Job do
  menu :priority => 8, :parent => 'Resources'
  permit_params :job_type_id, :scheduled_by, :recurrent, :scheduled_at, :cron

  %i[scheduled_at scheduled_by recurrent created_at updated_at is_disabled].each { |f| filter f }

  form :partial => 'form'

  action_item :create_sync_job, :only => :index do
    link_to 'Create Synchronization Job', new_admin_job_path(type: 'synchronize_direct_schedules')
  end

  scope :all
  scope :synchronization, :default => true do |jobs|
    jobs.where("key  = 'synchronize_contract'")
  end
  scope :direct_synchronization do |jobs|
    jobs.where("key = 'synchronize_direct_schedules'")
  end
  scope :restart do |jobs|
    jobs.where("key = 'restart'")
  end
  scope :update_notification do |jobs|
    jobs.where("key = 'update_notification'")
  end

  index do
    selectable_column
    column :detail do |job|
      link_to 'Detail', :controller => 'jobs', :action => 'show', :id => job.id
    end
    column :id do |job|
      link_to job.id, admin_job_path(job)
    end
    column :job_type
    column :entity do |job|
      if job.job_type.key == 'synchronize_contract'
        entity = JobEntity.find_by_job_id(job.id)
        contract = Contract.find_by_id(entity.r_contract)
        link_to "#{contract.customer.name} - #{contract.name}", admin_contract_path(contract)
      end
    end
    column :scheduled_by do |job|
      AdminUser.find_by_id(job.scheduled_by)&.email
    end
    column :scheduling do |job|
      if job.recurrent
        job.cron
      else
        job.scheduled_at
      end
    end
    column :started_at
    column :finished_at
    column :status do |job|
      value = job.status
      if value == 'WAITING'
        status_tag value, :warning
      elsif value =='FINISHED' || value =='RUNNING'
        status_tag value, :ok
      else
        status_tag value, :error
      end
    end
    column :log do |job|
      unless job.job_history_id.nil?
        link_to 'Log', :controller => 'jobs', :action => 'job_history_log', :id => job.job_history_id, :target => '_blank'
      end

    end
  end

  show do |at|
    job = Job.joins(:job_type).find(params['id'])

    panel('Detail') do
      attributes_table_for job do
        row :job_type
        row :scheduled_at
        row :scheduled_by do |job|
          AdminUser.find_by_id(job.scheduled_by)&.email
        end
        row :recurrent
        row :cron if job.recurrent
      end
    end
    if job.job_type.key == 'restart'
      panel('') do
        table_for JobEntity.get_job_entities_schedule(params['id']) do
          column(:project_name)
          column(:graph_name)
          column(:mode)
          column(:status) do |job_entity|
            value = job_entity.status
            if value =='WAITING' || value =='RUNNING'
              status_tag value, :warning
            elsif value =='FINISHED' || value =='DONE'
              status_tag value, :ok
            else
              status_tag value, :error
            end
          end
        end
      end
    elsif job.job_type.key == 'synchronize_contract'
      panel('Contract') do
        attributes_table_for Contract.contract_by_job_id(params['id']) do
          row :name
        end
      end
      panel('Setting Parameters') do
        table_for JobParameter.where('job_id = ?', params['id']) do
          column(:key)
          column(:value)
        end
      end

      panel('History') do
        table_for JobHistory.where('job_id = ?', params['id']).order('started_at DESC').limit(10) do
          column(:status) do |job_history|
            value = job_history.status
            if value == 'WAITING'
              status_tag value, :warning
            elsif value =='FINISHED' || value =='RUNNING'
              status_tag value, :ok
            else
              status_tag value, :error
            end
          end
          column(:started_at)
          column(:finished_at)
          column(:log) do |job_history|
            link_to 'Log', :controller => 'jobs', :action => 'job_history_log', :id => job_history.id, :target => '_blank'
          end
          column(:created_at)
        end
      end
    end
  end

  member_action :job_history_log do
    @log = JobHistory.find_by_id(params[:id])&.log
    # This will render app/views/admin/posts/comments.html.erb
  end

  controller do
    layout 'active_admin', :only => %i[new edit]
    include ApplicationHelper

    def scoped_collection
      Job.default
    end

    def edit
      @edit = true
      @job = SynchronizationJob.find_by_id(params['id'])
      temp_job = Job.find_by_id(params['id'])
      if @job.job_type.key == 'synchronize_contract'
        @type = 'synchronize_contract'
        @job.settings_server_id = temp_job.job_entities.first.r_settings_server
        @contract = temp_job.job_entities.first.r_contract
        @contract_name = Contract.find_by_id(@contract)&.name
        @parameters = []
        temp_job.job_parameters.each do |param|
          if param.key == 'mode'
            @job.param_mode = param.value
          elsif param.key == 'resource'
            @job.param_resource = param.value
          end
        end
        render 'synchronize_contract_job'
      elsif @job.job_type.key == 'synchronize_direct_schedules'
        @type = 'synchronize_direct_schedules'
        @job.settings_server_id = temp_job.job_entities.first.r_settings_server
        render 'synchronize_direct_job'
      end
    end

    def update
      job = Job.find_by_id(params['job_id'])

      if params['synchronization_job']['key'] == 'synchronize_contract'
        #Update JOB
        date = "#{params['synchronization_job']['scheduled_at_date']}T#{params['synchronization_job']['scheduled_at_time_hour']}:#{params['synchronization_job']['scheduled_at_time_minute']}:00"
        schedule_at = DateTime.strptime(date, '%Y-%m-%dT%H:%M:%S')
        job.recurrent = params['synchronization_job']['recurrent']
        job.scheduled_at = schedule_at
        job.cron = params['synchronization_job']['cron']

        #Update Job_entity
        job.job_entities.first.r_settings_server = params['synchronization_job']['settings_server_id']

        #Update Job_params
        job.job_parameters.each do |param|
          if param.key == 'mode'
            param.value = params['synchronization_job']['param_mode']
          elsif param.key == 'mode'
            param.value = params['synchronization_job']['param_resource']
          end
        end

        ActiveRecord::Base.transaction do
          job.save
        end
        redirect_to admin_job_path(params['job_id']), :notice => 'Job was updated!'
      elsif params['synchronization_job']['key'] == 'synchronize_direct_schedules'
        #Update JOB
        date = "#{params['synchronization_job']['scheduled_at_date']}T#{params['synchronization_job']['scheduled_at_time_hour']}:#{params['synchronization_job']['scheduled_at_time_minute']}:00"
        schedule_at = DateTime.strptime(date, '%Y-%m-%dT%H:%M:%S')
        job.recurrent = params['synchronization_job']['recurrent']
        job.scheduled_at = schedule_at
        job.cron = params['synchronization_job']['cron']

        #Update Job_entity
        job.job_entities.first.r_settings_server = params['synchronization_job']['settings_server_id']
        ActiveRecord::Base.transaction do
          job.save
        end
        redirect_to admin_job_path(params['job_id']), :notice => 'Job was updated!'
      end
    end


    def new
      if params['type'] == 'restart'
        job_type = JobType.find_by_key(params['type'])
        @job = Job.new(:job_type_id => job_type.id, :recurrent => false, :scheduled_at => DateTime.now)
        @entities = []
        selection_array = []
        schedules = Schedule.with_project.non_deleted.find(params['selection'])
        schedules.each do |s|
          job_entity = {:type => 'Schedule', :project => s.project_name, :graph_name => s.graph_name, :mode => s.mode, :status => 'NEW'}
          selection_array.push(s.id)
          @entities.push(job_entity)
        end
        @selection = selection_array.join(',')
        render 'restart_job'
      elsif params['type'] == 'synchronize_contract'
        @edit = false
        job_type = JobType.find_by_key(params['type'])
        @job = SynchronizationJob.new(:job_type_id => job_type.id, :recurrent => 'false', :scheduled_at => DateTime.now)
        #@jobs = CustomJobSynchronization.new({:job_type_id => job_type.id,:recurrent => "false",:scheduled_at => DateTime.now})
        #@jobs = OpenStruct.new(:job_type_id => job_type.id,:recurrent => false,:scheduled_at => DateTime.now)

        @contract = params['contract']
        @contract_name = Contract.find_by_id(@contract)&.name
        @parameters = []
        @parameters.push('name' => 'param_mode', 'setting' => {:as => :string, :label => 'Mode'})
        @parameters.push('name' => 'param_resource', 'setting' => {:as => :string, :label => 'Resource'})
        render 'synchronize_contract_job'
      elsif params['type'] == 'synchronize_direct_schedules'
        @edit = false
        job_type = JobType.find_by_key(params['type'])
        @job = DirectScheduleJob.new(:job_type_id => job_type.id, :recurrent => 'true', :scheduled_at => DateTime.now)
        #@jobs = CustomJobSynchronization.new({:job_type_id => job_type.id,:recurrent => "false",:scheduled_at => DateTime.now})
        #@jobs = OpenStruct.new(:job_type_id => job_type.id,:recurrent => false,:scheduled_at => DateTime.now)
        render 'synchronize_direct_job'
      end
    end

    def create
      pp params
      if params.key?('job')
        date = "#{params['job']['scheduled_at_date']}T#{params['job']['scheduled_at_time_hour']}:#{params['job']['scheduled_at_time_minute']}:00"
        schedule_at = DateTime.strptime(date, '%Y-%m-%dT%H:%M:%S')
        schedules = params['job']['selection'].split(',')
        job_type = JobType.find_by_key(params['job']['key'])
        ActiveRecord::Base.transaction do
          job = Job.create(:job_type_id => job_type.id, :scheduled_by => current_active_admin_user.id, :recurrent => false, :scheduled_at => schedule_at)
          schedules.each do |e|
            JobEntity.create(:job_id => job.id, :status => 'WAITING', :r_schedule => e)
          end
        end
        redirect_to admin_jobs_path, :notice => 'Job was create!'
      elsif params.key?('synchronization_job') && params['synchronization_job']['key'] =='synchronize_contract'
        # Parameters initialization
        date = "#{params['synchronization_job']['scheduled_at_date']}T#{params['synchronization_job']['scheduled_at_time_hour']}:#{params['synchronization_job']['scheduled_at_time_minute']}:00"
        schedule_at = DateTime.strptime(date, '%Y-%m-%dT%H:%M:%S')
        contract = params['synchronization_job']['contract']
        recurrent = params['synchronization_job']['recurrent']
        job_type = JobType.find_by_key(params['synchronization_job']['key'])
        cron = params['synchronization_job']['cron']


        parameters = []
        params['synchronization_job'].each_pair do |key, value|
          if key.include?('param_')
            parameters.push(:key => key.gsub('param_', ''), :value => value)
          end
        end
        #DB Save
        # scheduled_at - converting to UTC
        ActiveRecord::Base.transaction do
          job = Job.create(:job_type_id => job_type.id, :scheduled_by => current_active_admin_user.id, :recurrent => recurrent, :scheduled_at => schedule_at.utc, :cron => cron)
          JobEntity.create(:job_id => job.id, :status => 'WAITING', :r_contract => contract, :r_settings_server => params['synchronization_job']['settings_server_id'])
          parameters.each do |p|
            JobParameter.create(:job_id => job.id, :key => p[:key], :value => p[:value])
          end
        end
        redirect_to admin_jobs_path, :notice => 'Job was create!'
      elsif params.key?('direct_schedule_job') && params['direct_schedule_job']['key'] =='synchronize_direct_schedules'
        # Parameters initialization
        date = "#{params['direct_schedule_job']['scheduled_at_date']}T#{params['direct_schedule_job']['scheduled_at_time_hour']}:#{params['direct_schedule_job']['scheduled_at_time_minute']}:00"
        schedule_at = DateTime.strptime(date, '%Y-%m-%dT%H:%M:%S')
        contract = params['direct_schedule_job']['contract']
        recurrent = params['direct_schedule_job']['recurrent']
        job_type = JobType.find_by_key(params['direct_schedule_job']['key'])
        cron = params['direct_schedule_job']['cron']
        #DB Save
        # scheduled_at - converting to UTC
        ActiveRecord::Base.transaction do
          job = Job.create(:job_type_id => job_type.id, :scheduled_by => current_active_admin_user.id, :recurrent => recurrent, :scheduled_at => schedule_at.utc, :cron => cron)
          JobEntity.create(:job_id => job.id, :status => 'WAITING', :r_settings_server => params['direct_schedule_job']['settings_server_id'])
        end
        redirect_to admin_jobs_path, :notice => 'Job was created.'
      end
    end
  end
end
