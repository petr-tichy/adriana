$: << File.expand_path(File.dirname(__FILE__) + "../")

require 'parse-cron'
require_relative "data/connection.rb"
require 'logger'
require_relative 'migration.rb'
#require 'composite_primary_keys'
require 'google_drive'
require "passwordmanager"

%w(crontab_parser log helper change_watcher).each {|a| require_relative "helpers/#{a}"}
%w(project task).each {|a| require_relative "data/stage/#{a}"}
%w(execution_log project settings schedule project_history schedule_history event_log request sla_description running_executions contract project_detail settings_server notification_log customer).each {|a| require_relative "data/log/#{a}"}
%w(base timeline projects statistics).each {|a| require_relative "objects/#{a}"}
%w(events severity key event test livetest startedtest finishedtest slatest error_test).each {|a| require_relative "tests/#{a}"}
%w(splunk_downloader).each {|a| require_relative "splunk/#{a}"}
%w(synchronize execution).each {|a| require_relative "snifer/#{a}"}
%w(google_downloader).each {|a| require_relative "google/#{a}"}
%w(testcases).each {|a| require_relative "testcases/#{a}"}
#%w(notification_removal_task).each {|a| require_relative "custom/#{a}"}


module SLAWatcher

  class << self


    attr_accessor :google,:pd_service,:pd_entity

    def connect_to_db(hostname,port,username,password,database)
      SLAWatcher::Connection.connect(hostname,port,username,password,database)
    end

    def splunk(username,password,hostname)
      SLAWatcher::SplunkDownloader.new(username,hostname)
    end


    def client()
      SLAWatcher::Base.new()
    end


    def get_projects
      SLAWatcher::Project.load_projects
    end

    def check_request_id(values,type)
      #Fill temp_request table
      SLAWatcher::Request.delete_all()
      batch_size = 500
      batch = []
      values.each do |value|
        batch << SLAWatcher::Request.new(:request_id => value[:request_id])
        if batch.size >= batch_size
          SLAWatcher::Request.import batch
          batch = []
        end
      end
      SLAWatcher::Request.import batch

      if (type == 'STARTED')
        requests = SLAWatcher::Request.check_request_id_started
      else
        requests = SLAWatcher::Request.check_request_id_finished
      end

      values.delete_if do |element|
        e = requests.find{|r| r.request_id == element[:request_id]}
        if (e.nil?)
          true
        else
          false
        end
      end
      values
    end

    def load_last_run
      Helper.value_to_datetime(SLAWatcher::Settings.load_last_splunk_synchronization.first.value)
    end

    def save_last_run(time)
      SLAWatcher::Settings.save_last_splunk_synchronization(time)
    end

    def log_execution(pid,graph_name,mode,status,detailed_status,time = nil)
      SLAWatcher::ExecutionLog.log_execution(pid,graph_name,mode,status,detailed_status,time)
    end

    def log_execution_splunk(pid,graph_name,mode,status,detailed_status,time = nil,request_id = nil)
      SLAWatcher::ExecutionLog.log_execution_splunk(pid,graph_name,mode,status,detailed_status,time,request_id)
    end

    def start_migration()
      migration = SLAWatcher::Migration.new()
      migration.compare_stage_log_project
      migration.compare_stage_log_schedule
    end

    def test()
      @events = []

      errorTest = SLAWatcher::ErrorTest.new()
      @events = @events + errorTest.start

      finishedTest = SLAWatcher::FinishedTest.new()
      @events = @events + finishedTest.start

      livetest = SLAWatcher::LiveTest.new()
      @events = @events + livetest.start

      startedTest = SLAWatcher::StartedTest.new()
      @events = @events + startedTest.start

      events_wrapper = Events.new(@events,@pd_service,@pd_entity)
      events_wrapper.save
    end

    def development()
      #events = Events.new
      ##
      #contractErrorTest = SLAWatcher::ContractErrorTest.new(events)
      #contractErrorTest.start

      @events = []

      finishedTest = SLAWatcher::FinishedTest.new()
      @events = @events + finishedTest.start

      pp @events

      #errorTest = SLAWatcher::ErrorTest.new()
      #@events = @events + errorTest.start

      #livetest = SLAWatcher::LiveTest.new()
      #@events = @events + livetest.start

      #startedTest = SLAWatcher::StartedTest.new()
      #@events = @events + startedTest.start

      events_wrapper = Events.new(@events,@pd_service,@pd_entity)
      events_wrapper.save

    end


    def run_test_case()
      TestCase.testcase12()
      #TestCase.cleartestcases
    end


    def get_sla_descriptions
      SLAWatcher::SLADescription.get_data_for_sheet
    end

    def get_unchanged_sla_descriptions
      SLAWatcher::SLADescription.select("*")
    end

    def get_wrongly_logged_executions
      SLAWatcher::ExecutionLog.get_wrongly_logged_executions
    end


    def connect_to_google(login,password,document)
      @google =  SLAWatcher::GoogleDownloader.new(login,password,document,0)
    end


    def snifer
      synchronize = SLAWatcher::Synchronize.new
      synchronize.load_data
      synchronize.work
    end

    def run_notification_removal_task
      removal_task = SLAWatcher::NotificationRemovalTask.new
      removal_task.start
    end








  end

end