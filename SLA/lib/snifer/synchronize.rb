require 'gooddata'
require 'benchmark'

module SLAWatcher
  class Synchronize
    SCHEDULES_PER_THREAD = 200

    def load_data
      @@log.info 'Starting the API snifer'
      @last_execution = Helper.value_to_datetime(Settings.load_last_splunk_synchronization.first.value)
      @now = DateTime.now

      load_sources
      load_resources_from_sources
      load_passwords_for_resources

      @@log.info 'Resources loaded successfully'
    end

    def load_sources
      # Lets load generic resources for servers
      @servers = SettingsServer.where("server_type = 'cloudconnect'")
      # Lets load the Contract specific resources
      @contracts = Contract.where("resource IS NOT NULL")
      @schedules = Schedule.joins(:settings_server).joins(:project).joins(:contract).where("server_type = 'cloudconnect' and schedule.is_deleted = 'f' and project.is_deleted = 'f'")
    end

    def load_resources_from_sources
      @resources = []
      @servers.each do |s|
        @resources.push('uniq' => s.name, 'name' => s.default_account, 'type' => 'global', 'server_id' => s.id)
      end
      @schedules.each do |s|
        @resources.push('uniq' => s['contract_id'], 'name' => s['contract_resource'], 'type' => 'contract', 'contract_id' => s['contract_id'])
      end
      @resources.uniq! { |s| s['uniq'] }
      @resources.delete_if { |s| s['name'].nil? || s['name'].empty? }
    end

    # Load passwords for resources from PassMan
    def load_passwords_for_resources
      @@log.info 'Loading resource from Password Manager'
      @resources.each do |resource|
        resource['username'] = resource['name'].split('|').last
        resource['password'] = PasswordManagerApi::Password.get_password_by_name(resource['name'].split('|').first, resource['name'].split('|').last)
      end
    end

    # Save execution logs for all applicable executions
    def log_executions
      @execution_start = []
      @execution_end = []
      @thread_resources = []

      prepare_thread_resources

      @mutex = Mutex.new
      threads = @thread_resources.map do |schedules, resource|
        Thread.new { get_executions_info(schedules, resource) }
      end
      threads.each(&:join)

      starts = check_request_id(@execution_start, 'STARTED')
      errors_finished = check_request_id(@execution_end, 'FINISHED')

      # Save the events to the database
      # We need to use transaction, because of UPDATE on the end of the query
      ActiveRecord::Base.transaction do
        (starts + errors_finished).each do |e|
          ExecutionLog.log_execution_api(e['schedule_id'], e['status'], 'From Splunk synchronizer', e['event_time'], e['execution_id'])
        end

        # Save the last run date
        Settings.save_last_splunk_synchronization(@now)
      end
      @@log.info 'The API snifer has finished'
    end

    def prepare_thread_resources
      @resources.each do |resource|
        resource_schedules = case resource['type']
                             when 'global'
                               @schedules.find_all { |s| s.settings_server_id == resource['server_id'] }
                             when 'contract'
                               @schedules.find_all { |s| s['contract_id'] == resource['contract_id'] }
                             else
                               []
                             end
        counter = 0
        elements = []
        resource_schedules.each do |e|
          elements << e
          counter += 1
          if counter >= SCHEDULES_PER_THREAD
            @thread_resources.push([elements, resource])
            elements = []
            counter = 0
          end
        end
        @thread_resources << [elements, resource] if elements.count > 0
      end
    end

    def get_executions_info(schedules, resource)
      execution_start = []
      execution_end = []

      settings_server = @servers.find { |s| s.id == resource['server_id'] }
      client = GoodData.connect(resource['username'], resource['password'], server: settings_server.server_url)

      schedules.each do |schedule|
        executions = download_executions(schedule, client)
        next unless executions
        execution_start += executions[0]
        execution_end += executions[1]
      end

      client.disconnect

      @mutex.synchronize do
        @execution_start += execution_start
        @execution_end += execution_end
      end
    end

    def download_executions(schedule, client)
      execution_start_list = []
      execution_end_list = []
      gd_schedule = schedule.gooddata_schedule
      r_project = schedule.r_project

      # Ignoring pagination, because the default is good enough (last 100 executions)
      response = Helper.retryable do
        client.get("/gdc/projects/#{r_project}/schedules/#{gd_schedule}/executions")
      end
      last_execution_offset = @last_execution - 24.hours
      response['executions']['items'].each do |e|
        execution = Execution.new(e)
        if execution.running? && execution.start_time > last_execution_offset
          execution_start_list << execution_log_hash(execution.id, execution.start_time, 'STARTED', gd_schedule, r_project)
        elsif (execution.ok? || execution.error?) && (execution.start_time > last_execution_offset || execution.end_time > last_execution_offset)
          execution_start_list << execution_log_hash(execution.id, execution.start_time, 'STARTED', gd_schedule, r_project)
          execution_end_list << execution_log_hash(execution.id, execution.end_time, execution.ok? ? 'FINISHED' : 'ERROR', gd_schedule, r_project)
        end
      end
      [execution_start_list, execution_end_list]
    rescue => e
      @@log.warn "Problem in downloading schedule (#{gd_schedule}) for #{r_project} - #{e.message}"
    end

    def execution_log_hash(id, event_time, status, schedule_id, project_pid)
      {
          'execution_id' => id,
          'event_time' => event_time,
          'status' => status,
          'schedule_id' => schedule_id,
          'project_pid' => project_pid
      }
    end

    def check_request_id(values, type)
      #Fill temp_request table
      Request.delete_all
      batch_size = 500
      batch = []
      values.each do |value|
        batch << Request.new(:request_id => value['execution_id'])
        if batch.size >= batch_size
          Request.import batch
          batch = []
        end
      end
      Request.import batch

      requests = (type == 'STARTED' ? Request.check_request_id_started : Request.check_request_id_finished)

      values.delete_if do |element|
        e = requests.find { |r| r.request_id == element['execution_id'] }
        e.nil?
      end
      values
    end
  end
end