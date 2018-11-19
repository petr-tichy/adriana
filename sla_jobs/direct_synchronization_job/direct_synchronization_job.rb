require_relative '../job_exception'
%w[schedule job_entity settings_server job_parameter project admin_user].each { |x| require_relative '../../app/models/' + x }
require 'gooddata'

module DirectSynchronizationJob
  class DirectSynchronizationJob
    JOB_KEY = 'synchronize_direct_schedules'.freeze
    REQUIRED_PARAMS = %w[].freeze

    attr_accessor :job_id, :credentials

    def initialize(job_id, credentials)
      @job_id = job_id
      @credentials = credentials
    end

    def connect
      self.class.connect_to_passman(@credentials[:passman][:address], @credentials[:passman][:port], @credentials[:passman][:key])
    end

    def run
      load_data
      $log.info "Processing #{JOB_KEY} job: #{@job_id} on server #{@settings_server.name}"
      resource = @settings_server.default_account
      username, password = load_resource_credentials(resource) # Load credentials from passman
      self.class.connect_to_gd(username, password, @settings_server)

      process_schedules
    end

    def process_db_schedule(db_schedule, gd_schedule)
      if !gd_schedule.nil? && gd_schedule.state != 'DISABLED'
        if gd_schedule.params.include?('EXECUTABLE') || gd_schedule.params.include?('GRAPH')
          # The schedule is in Gooddata and in DB
          graph_name = gd_schedule.params['EXECUTABLE'].match(/[^\/]*$/) unless gd_schedule.params['EXECUTABLE'].nil?
          graph_name = gd_schedule.params['GRAPH'].match(/[^\/]*$/) unless gd_schedule.params['GRAPH'].nil?

          # Logic around max_number_of_errros
          max_number_of_errors = db_schedule.max_number_of_errors || 2
          # For now, when the reschedule parameter is not set, we automatically set max_number_of_error to 0
          max_number_of_errors = 0 if gd_schedule.reschedule.nil?
          values = {
            'graph_name' => graph_name[0].downcase,
            'mode' => gd_schedule.params['MODE'].nil? ? '' : gd_schedule.params['MODE'].downcase,
            'cron' => gd_schedule.cron || '',
            'max_number_of_errors' => max_number_of_errors
          }
          changed = Schedule.update_with_history(@user, db_schedule.id, values)
          if changed
            $log.info "The schedule #{gd_schedule.uri.split('/').last} has changed"
            $log.info " Old values (graph_name,mode,cron,max_number_of_errors) (#{db_schedule.graph_name},#{db_schedule.mode},#{db_schedule.cron},#{db_schedule.max_number_of_errors}"
            $log.info " New values (graph_name,mode,cron,max_number_of_errors) (#{graph_name[0].downcase},#{gd_schedule.params['MODE'].nil? ? '' : gd_schedule.params['MODE'].downcase},#{gd_schedule.cron},#{max_number_of_errors}"
          end
        end
      else
        # Schedule is in DB but it is not in GD
        Schedule.mark_deleted(db_schedule.id, @user)
        $log.info "The schedule #{db_schedule.gooddata_schedule} was marked as deleted \n"
      end
    end

    def process_gd_schedule(gd_schedule, project)
      return unless gd_schedule.params.include?('EXECUTABLE') || gd_schedule.params.include?('GRAPH')
      graph_name = gd_schedule.params['EXECUTABLE'].match(/[^\/]*$/) unless gd_schedule.params['EXECUTABLE'].nil?
      graph_name = gd_schedule.params['GRAPH'].match(/[^\/]*$/) unless gd_schedule.params['GRAPH'].nil?
      max_number_of_errors = 2
      # For now, when the reschedule parameter is not set, we automaticaly set max_number_of_error to 0
      max_number_of_errors = 0 if gd_schedule.reschedule.nil?
      values = {
        'graph_name' => graph_name[0].downcase,
        'mode' => gd_schedule.params['MODE'].nil? ? '' : gd_schedule.params['MODE'].downcase,
        'cron' => gd_schedule.cron || '',
        'settings_server_id' => @settings_server.id,
        'r_project' => project.project_pid,
        'gooddata_schedule' => gd_schedule.uri.split('/').last,
        'gooddata_process' => gd_schedule.params['PROCESS_ID'],
        'max_number_of_errors' => max_number_of_errors
      }
      Schedule.create_with_history(@user, values)
      $log.info "The schedule #{gd_schedule.uri.split('/').last} was created"
      $log.info " Values (graph_name,mode,cron,settings_server_id,r_project,gooddata_schedule,gooddata_process,max_number_of_errors) (#{graph_name[0].downcase},#{gd_schedule.params['MODE'].nil? ? '' : gd_schedule.params['MODE'].downcase},#{gd_schedule.cron},#{@settings_server.id},#{project.project_pid},#{gd_schedule.uri.split('/').last},#{gd_schedule.params['PROCESS_ID']},#{max_number_of_errors}"
    end

    def process_schedules
      gooddata_projects = GoodData::Project.all

      @projects.each do |project|
        #Project is in DB and in GoodData
        gd_project = gooddata_projects.find { |p| p.obj_id == project.project_pid }
        next if gd_project.nil?
        db_schedules = @schedules.find_all { |s| s.r_project == project.project_pid }
        gd_schedules = gd_project.schedules
        gd_schedules.delete_if { |s| s.type != 'MSETL' }

        db_schedules.each do |db_schedule|
          gd_schedule = gd_schedules.find { |s| s.uri.split('/').last == db_schedule.gooddata_schedule }
          process_db_schedule(db_schedule, gd_schedule)
        end
        # Schedule is in GD but it is not in DB
        gd_schedules.find_all { |s| s.state != 'DISABLED' }.each do |gd_schedule|
          db_schedule = db_schedules.find { |s| gd_schedule.uri.split('/').last == s.gooddata_schedule }
          next unless db_schedule.nil?
          process_gd_schedule(gd_schedule, project)
        end
      end
    end

    #TODO dry
    def load_resource_credentials(resource)
      $log.info 'Loading resource from Password Manager'
      resource_array = resource.split('|')
      username = resource_array[1]
      password = PasswordManagerApi::Password.get_password_by_name(resource_array[0], resource_array[1])
      $log.info 'Resource loaded successfully'
      [username, password]
    end

    #TODO: dry
    def load_data
      # In case of sychronization activity, there is only one entity connected to JOB
      @job_entity = JobEntity.find_by_job_id(@job_id)
      @settings_server = SettingsServer.find(@job_entity.r_settings_server)
      @job_parameters = JobParameter.where('job_id = ?', @job_id)
      @projects = Project.joins(:contract).where(contract: {contract_type: 'direct'}, project: {is_deleted: false})
      @schedules = Schedule.joins(:project).joins(:contract).where(contract: {contract_type: 'direct'}, project: {is_deleted: false}, schedule: {is_deleted: false})
      @user = AdminUsers.find_by_email('ms@gooddata.com')
    end

    class << self
      #TODO: dry
      def connect_to_gd(username, password, settings_server)
        $log.info "Connecting to Gooddata server #{settings_server.server_url} webdav #{settings_server.webdav_url}"
        GoodData.logger = $log
        GoodData.logger.level = Logger::DEBUG
        GoodData.connect(username, password, :server => settings_server.server_url, :webdav_server => settings_server.webdav_url, :headers => {:accept => 'application/json;version=1'})
      end
    end
  end
end