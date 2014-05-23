$: << File.expand_path(File.dirname(__FILE__) + "/")

require 'parse-cron'
require_relative "../lib/data/connection.rb"
require 'logger'
require_relative '../lib/migration.rb'
require 'composite_primary_keys'
require 'google_drive'

%w(crontab_parser log helper change_watcher).each {|a| require_relative "../lib/helpers/#{a}"}
%w(project task).each {|a| require_relative "../lib/data/stage/#{a}"}
%w(execution_log project settings schedule project_history schedule_history event_log request sla_description running_executions contract project_detail settings_server).each {|a| require_relative "../lib/data/log/#{a}"}
%w(base timeline projects statistics).each {|a| require_relative "../lib/objects/#{a}"}
%w(events severity key event test livetest startedtest finishedtest slatest contract_error_test).each {|a| require_relative "../lib/tests/#{a}"}
%w(splunk_downloader).each {|a| require_relative "../lib/splunk/#{a}"}
%w(google_downloader).each {|a| require_relative "../lib/google/#{a}"}
%w(testcases).each {|a| require_relative "../lib/testcases/#{a}"}



module SLAWatcher

  class << self


    attr_accessor :google

    def connect_to_db(hostname,port,username,password,database)
      SLAWatcher::Connection.connect(hostname,port,username,password,database)
    end

    def splunk(username,hostname)
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
      events = Events.new

      livetest = SLAWatcher::LiveTest.new(events)
      livetest.start
      ##
      startedTest = SLAWatcher::StartedTest.new(events)
      startedTest.start
      #
      finishedTest = SLAWatcher::FinishedTest.new(events)
      finishedTest.start

      #slaTest = SLAWatcher::SlaTest.new(events)
      #slaTest.start

      events.mail_incident
      #events.mail_status
      events.save
    end

    def development()
      #events = Events.new
      ##
      #contractErrorTest = SLAWatcher::ContractErrorTest.new(events)
      #contractErrorTest.start

      time = DateTime.now.utc - 2.hours
      counter = 0
      while (counter < 15)
        puts "Current time: #{time.strftime("%T")}"
        next_run =  SLAWatcher::Helper.next_run("30 7,8,9,13,14,16,17 * * *",time,SLAWatcher::UTCTime)
        puts "Next run: #{next_run.strftime("%T")}"
        time = time + 30.minutes
        counter += 1
      end






      #

      #
      #events.each do |e|
      #  puts "----------------- Event START -------------------------"
      #  puts e.to_s
      #  puts "----------------- Event STOP  -------------------------"
      #end


      #pp ExecutionLog.get_last_events_in_interval("test",["prod2","prod3"],"app",DateTime.now - 12.hour)
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








  end

end