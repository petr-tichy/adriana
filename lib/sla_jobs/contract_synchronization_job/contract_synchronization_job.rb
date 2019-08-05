require_relative '../job_exception'
require_relative '../job_helper'
require_relative '../../credentials_helper'
require 'gooddata'

module ContractSynchronizationJob
  class ContractSynchronizationJob
    JOB_KEY = :synchronize_contract
    REQUIRED_PARAMS = %w[mode resource].freeze

    attr_accessor :job_id, :credentials, :mode_pattern

    def initialize(job_id, credentials)
      @credentials = credentials
      @job_id = job_id
    end

    def connect
      #TODO: credentials validation
      CredentialsHelper.connect_to_passman(@credentials[:passman][:address], @credentials[:passman][:port], @credentials[:passman][:key])
    end

    def run
      load_data
      $log.info "Processing #{JOB_KEY} job: #{@job_id} on server #{@settings_server.name}"
      check_required_params
      @mode_pattern = @job_parameters.find { |x| x.key.casecmp('mode').zero? }.value.downcase

      resource = @job_parameters.find { |x| x.key.casecmp('resource').zero? }.value
      begin
        username, password = CredentialsHelper.load_resource_credentials(resource) # Load credentials from passman
        raise PassmanCredentialsError, "Couldn't obtain password from Passman for resource #{resource}." if password.to_s.empty?
      end
      self.class.connect_to_gd(username, password, @settings_server)

      processes = self.class.get_all_user_processes

      raise JobException.new(@job_id, 'The API has returned no processes, aborting.') unless processes.any?

      # Delete schedules that are in DB but not in GoodData
      @schedules.each do |schedule|
        gd_process = processes.find { |p| p[:schedule] == schedule.gooddata_schedule }
        delete_schedule(gd_process, schedule)
      end
      load_data # Reload data in case some schedules were deleted

      processes.each { |process| synchronize_process(process) }
      $log.info 'Contract synchronization job has finished successfully.'
    end

    private

    def add_schedule(process, graph, mode)
      now = DateTime.now
      project_values = {
        'project_pid' => process[:project_pid],
        'status' => 'Live',
        'name' => process[:project_name],
        'updated_by' => @user.id,
        'updated_at' => now,
        'created_at' => now,
        'contract_id' => @contract.id,
        'sla_enabled' => false
      }
      project = Project.find(process[:project_pid]) rescue nil
      max_number_of_errors = @contract.default_max_number_of_errors
      max_number_of_errors = 0 if process[:reschedule].nil?
      schedule_values = {
        'name' => process[:name],
        'process_name' => process[:process_name],
        'graph_name' => graph,
        'mode' => mode,
        'cron' => process[:cron] || '',
        'updated_by' => @user.id,
        'r_project' => process[:project_pid],
        'main' => true,
        'created_at' => now,
        'settings_server_id' => @settings_server.id,
        'gooddata_schedule' => process[:schedule],
        'gooddata_process' => process[:process],
        'max_number_of_errors' => max_number_of_errors
      }
      ActiveRecord::Base.transaction do
        if project.nil?
          $log.info "Creating new project (project_pid: #{process[:project_pid]})"
          Project.create_with_history(@user, project_values)
        else
          $log.info "Updating project (project_pid: #{process[:project_pid]})"
          Project.update_with_history(@user, process[:project_pid], project_values)
        end
        $log.info "Creating new schedule - graph: #{graph}, mode: #{mode}"
        Schedule.create_with_history(@user, schedule_values)
      end
    end

    def update_schedule(process, graph, mode, schedule)
      max_number_of_errors = schedule.max_number_of_errors
      max_number_of_errors = 0 if process[:reschedule].nil?
      schedule_values = {
        'name' => process[:name],
        'process_name' => process[:process_name],
        'graph_name' => graph,
        'mode' => mode,
        'cron' => process[:cron] || '',
        'gooddata_schedule' => process[:schedule],
        'gooddata_process' => process[:process],
        'is_deleted' => false,
        'updated_by' => @user.id,
        'max_number_of_errors' => max_number_of_errors
      }
      project_values = {
        'status' => 'Live',
        'name' => process[:project_name],
        'updated_by' => @user.id, 'is_deleted' => false}
      ActiveRecord::Base.transaction do
        changed_project = Project.update_with_history(@user, process[:project_pid], project_values)
        changed_schedule = Schedule.update_with_history(@user, schedule.id, schedule_values)
        $log.info "Updating project (project_pid: #{process[:project_pid]}" if changed_project
        $log.info "Updating schedule (graph: #{graph}, mode: #{mode})" if changed_schedule
      end
    end

    def delete_schedule(process, schedule)
      mode = process.dig(:params, 'MODE')&.downcase || '' unless process.nil?
      # This means that process was deleted from GOODDATA
      return unless !schedule.is_deleted && (process.nil? || !mode.include?(@mode_pattern))
      ActiveRecord::Base.transaction do
        $log.info "Deleting project & schedule (project_pid: #{schedule.r_project}, graph: #{schedule.graph_name}, mode: #{schedule.mode})"
        Project.update_with_history(@user, schedule.r_project, 'is_deleted' => true)
        Schedule.update_with_history(@user, schedule, 'is_deleted' => true)
      end
    end

    def synchronize_process(process)
      schedule = @schedules.find { |s| s.gooddata_schedule == process[:schedule] }

      mode = process[:params]['MODE'].nil? ? '' : process[:params]['MODE'].downcase
      temp_executable = process[:params]['EXECUTABLE'].match(/[^\/]*$/) unless process[:params]['EXECUTABLE'].nil?
      temp_graph = process[:params]['GRAPH'].match(/[^\/]*$/) unless process[:params]['GRAPH'].nil?

      graph = !temp_graph.nil? ? temp_graph[0].downcase : temp_executable[0].downcase

      if schedule.nil?
        if mode.include?(@mode_pattern)
          # Add schedule (along with project if missing) to the monitoring DB
          add_schedule(process, graph, mode)
        else
          $log.info "Project #{process[:project_pid]} should not be monitored (doesn't have MODE set)."
        end
      elsif schedule.is_deleted == false || (mode.include?(@mode_pattern) && process[:state] != 'DISABLED')
        update_schedule(process, graph, mode, schedule)
      end
    end

    def check_required_params
      $log.info 'Checking required parameters'
      REQUIRED_PARAMS.each do |rp|
        param = @job_parameters.find { |p| p.key == rp }
        raise JobException.new(@job_id, "Missing required parameter: #{rp}") if param.nil?
      end
    end

    #TODO dry
    def load_data
      # In case of synchronization action, there is only one entity connected to JOB
      @job_entity = JobEntity.find_by_job_id(@job_id)
      @settings_server = SettingsServer.find(@job_entity.r_settings_server)
      @job_parameters = JobParameter.where('job_id = ?', @job_id)
      @contract = Contract.find(@job_entity.r_contract)
      @schedules = Schedule.joins(:project).where('project.contract_id = ? and schedule.is_deleted = ?', @contract.id, false)
      @user = AdminUser.gd_technical_admin
    end

    class << self
      #TODO dry
      def connect_to_gd(username, password, settings_server)
        $log.info "Connecting to Gooddata server #{settings_server.server_url} webdav #{settings_server.webdav_url}"
        GoodData.logger = $log
        GoodData.logger.level = Logger::DEBUG
        GoodData.connect(username, password, :server => settings_server.server_url, :webdav_server => settings_server.webdav_url, :headers => {:accept => 'application/json;version=1', :content_type => 'application/json'})
      end

      def get_all_user_processes
        limit = 50
        offset = 0
        finished = false
        objects = []

        $log.info 'Downloading process information from the platform'
        until finished
          $log.info "Downloading with page settings: offset - #{offset} limit - #{limit} "
          project_views = JobHelper.retryable do
            GoodData.get("/gdc/dataload/internal/projectsView?offset=#{offset}&limit=#{limit}")['projectsView']['items']
          end
          project_views.each do |view|
            processes_mapping = view['projectView']['processes'].each_with_object({}) do |process_hash, result_hash|
              # $.projectsView.items[*].projectView.processes[*].process.name
              name = process_hash.dig('process', 'name') rescue nil
              id = process_hash.dig('process', 'links', 'self').split('/').last rescue nil
              result_hash[id] = name if id && name
            end
            view['projectView']['schedules'].each do |schedule|
              next unless schedule['schedule']['type'] == 'MSETL'
              process_id = schedule['schedule']['params']['PROCESS_ID']
              objects.push(
                :process => process_id,
                :name => schedule['schedule']['name'],
                :process_name => processes_mapping[process_id],
                :project_pid => view['projectView']['id'].split("\/").last,
                :schedule => schedule['schedule']['links']['self'].split("\/").last,
                :project_name => view['projectView']['name'],
                :cron => schedule['schedule']['cron'],
                :timezone => schedule['schedule']['timezone'],
                :state => schedule['schedule']['state'],
                :params => schedule['schedule']['params'],
                :reschedule => schedule['schedule']['reschedule']
              )
            end
          end
          if project_views.count < limit
            finished = true
          else
            offset += limit
          end
        end
        $log.info 'Download has finished'
        objects
      end
    end
  end

end