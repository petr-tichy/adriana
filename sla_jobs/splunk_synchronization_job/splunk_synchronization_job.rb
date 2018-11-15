require 'passwordmanager'
require 'yaml'
require 'date'
require_relative 'splunk_downloader'
require_relative 'helper'
require 'activerecord-import'
require 'require_all'
require_rel '../../app/models'

module SplunkSynchronizationJob
  class SplunkSynchronizationJob
    JOB_TYPE = 'splunk_synchronization'.freeze
    attr_accessor :credentials, :splunk_downloader

    def initialize(credentials)
      @credentials = credentials
    end

    def connect
      self.class.connect_to_db
      #TODO credentials validation
      self.class.connect_to_passman(@credentials[:passman][:address], @credentials[:passman][:port], @credentials[:passman][:key])
      username = @credentials[:splunk][:username].split('|').last
      # Obtain password for Splunk from PasswordManager
      password = PasswordManagerApi::Password.get_password_by_name(@credentials[:splunk][:username].split('|').first, username)
      @splunk_downloader = SLAWatcher.splunk_downloader(username, password, @credentials[:splunk][:hostname])
      @splunk_downloader.errors_to_match = SLAWatcher.get_error_filter_messages
    end

    def run
      now, starts, errors_finished = load_runs_from_splunk
      save_runs_to_db now, starts, errors_finished
    end

    def load_runs_from_splunk
      # Load the last time when the synchronization was executed
      last_run = load_last_run
      now = DateTime.now
      # Load all CC projects that need to be monitored
      projects = Project.load_projects

      # Returns all events for given set of projects in given time frame
      events = @splunk_downloader.load_runs(last_run - 4.hours, now, projects)

      starts = events.find_all { |e| e[:status] == 'STARTED' }
      errors_finished = events.find_all { |e| e[:status] != 'STARTED' }

      starts = check_request_id(starts, 'STARTED')
      errors_finished = check_request_id(errors_finished, 'FINISHED')
      [now, starts, errors_finished]
    end

    def save_runs_to_db(timestamp_now, started_events, errors_finished_events)
      # Save the events to the database
      # We need to use a transaction, because of UPDATE on the end of the query
      ActiveRecord::Base.transaction do
        (started_events + errors_finished_events).each do |event|
          log_execution_splunk(event)
        end

        # Save the last run date
        save_last_run(timestamp_now)
      end
      # Flag files for monit
      flag_for_monit(JOB_TYPE)
    end

    class << self
      def connect_to_db
        ActiveRecord::Base.logger = $log
        config = YAML::safe_load(File.open('config/database.yml'))
        ActiveRecord::Base.establish_connection(config['database'])
      end

      def connect_to_passman(address, port, key)
        PasswordManagerApi::PasswordManager.connect(address, port, key)
      end
    end

    private

    def load_last_run
      Helper.value_to_datetime(Settings.load_last_splunk_synchronization.first.value)
    end

    def save_last_run(time)
      Settings.save_last_splunk_synchronization(time)
    end

    def check_request_id(values, type)
      # Fill temp_request table with request IDs from the events
      Request.delete_all
      batch_size = 500
      batch = []
      values.each do |value|
        batch << Request.new(:request_id => value[:request_id])

        next unless batch.size >= batch_size # Import and reset batch
        Request.import batch
        batch = []
      end
      Request.import batch # Import remaining batch

      # Find all execution_log for the request_ids and return those with empty request_id (depending on type)
      requests = type == 'STARTED' ? Request.check_request_id_started : Request.check_request_id_finished

      # Filter events to those, that do not have a connected execution_log request
      values.delete_if do |element|
        requests.find { |r| r.request_id == element[:request_id] }.nil?
      end
      values
    end

    def log_execution_splunk(event)
      ExecutionLog.log_execution_splunk(
        event[:project_pid],
        event[:schedule_id],
        event[:request_id],
        event[:clover_graph],
        event[:mode],
        event[:status],
        'From Splunk synchronizer',
        event[:time],
        event[:error_text],
        event[:matches_error_filters]
      )
    end

    def flag_for_monit(command)
      FileUtils.touch('monit/' + command.to_s + '_finished')
    end
  end
end