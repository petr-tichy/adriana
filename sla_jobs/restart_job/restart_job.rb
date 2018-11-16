require_relative '../job_exception'

module RestartJob
  class RestartJob
    JOB_KEY = 'restart'.freeze

    def initialize(job_id)
      @job_id = job_id
    end

    def run
      load_data
      $log.info "Processing #{JOB_KEY} job: #{@job_id} on server #{@settings_server.name}"
      error = false
      @project_by_server.each_pair do |k, v|
        server = @settings_server.find { |s| s.id == k }
        resource = @job_parameters.empty? ? server.default_account : @job_parameters.find { |p| p.key == 'resource' }.value
        fail 'There is no resource attached to this restart job execution' if resource.nil?

        username, password = load_resource_credentials(resource) # Load credentials from passman
        self.class.connect_to_gd(username, password, @settings_server)

        v.each do |schedule|
          entity = @job_entity.find { |e| e.r_schedule == schedule.id }
          response = Schedules.restart(schedule.r_project, schedule.gooddata_schedule)
          if response
            entity.status = 'DONE'
            entity.save
          else
            entity.status = 'ERROR'
            entity.save
            error = true
          end
        end
      end
      fail 'There was an error during the restart job.' if error

    end

    #TODO: dry
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
      @job_entity = JobEntity.where('job_id = ?', @job_id)
      @job_parameters = JobParameter.where('job_id = ?', @job_id)
      @schedules = Schedule.get_by_job_id(@job_id)
      @settings_server = SettingsServer.all

      # Lets filter only CC project and but them in multiple groups by CC server
      @project_by_server = {}
      @settings_server.each do |server|
        if server.server_type == 'cloudconnect'
          server_schedules = @schedules.find_all { |p| p.settings_server_id == server.id }
          @project_by_server[server.id] = server_schedules unless server_schedules.empty?
        end
      end
    end

    class << self
      #TODO: dry
      def connect_to_gd(username, password, settings_server)
        $log.info "Connecting to Gooddata server #{settings_server.server_url} webdav #{settings_server.webdav_url}"
        GoodData.logger = $log
        GoodData.logger.level = Logger::DEBUG
        GoodData.connect(username, password, :server => settings_server.server_url, :webdav_server => settings_server.webdav_url, :headers => {'X-GDC-CC-PRIORITY-MODE' => 'NORMAL'})
      end
    end
  end
end