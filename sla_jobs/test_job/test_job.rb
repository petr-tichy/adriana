require 'pagerduty/full'
require 'yaml'
require 'rest-client'
require 'pp'
require 'pony'
require 'date'
%w(events severity key event test live_test started_test error_test).each { |a| require_relative a }
require 'require_all'
require_rel '../../app/models'

module TestJob
  class TestJob
    JOB_TYPE = 'test'.freeze
    attr_accessor :credentials, :pd_entity, :pd_service

    def initialize(credentials, l2_pd_service, ms_pd_service)
      @credentials = credentials
      @pd_service = {l2: l2_pd_service, ms: ms_pd_service}
    end

    def connect
      self.class.connect_to_db
      @pd_entity = self.class.connect_to_pd(@credentials[:pager_duty][:api_key], @credentials[:pager_duty][:subdomain])
    end

    def run
      run_tests
      self.class.flag_for_monit(JOB_TYPE)
    end

    private

    def run_tests
      @events = []

      error_test = ErrorTest.new
      @events.concat error_test.start

      live_test = LiveTest.new
      @events.concat live_test.start

      if ping # Checks that the platform is running
        started_test = StartedTest.new
        @events.concat started_test.start
      end

      # Save the collected events to PagerDuty
      events_wrapper = Events.new(@events, @pd_service, @pd_entity)
      events_wrapper.save
    end

    def ping
      RestClient.get('https://secure.gooddata.com/gdc/ping')
      true
    rescue
      false
    end

    class << self
      def connect_to_db
        ActiveRecord::Base.logger = $log
        config = YAML::safe_load(File.open('config/database.yml'))
        ActiveRecord::Base.establish_connection(config[Rails.env])
      end

      def connect_to_pd(api_key, pd_subdomain)
        PagerDuty::Full.new(api_key, pd_subdomain)
      end

      def flag_for_monit(command)
        FileUtils.touch('monit/' + command.to_s + '_finished')
      end
    end
  end
end