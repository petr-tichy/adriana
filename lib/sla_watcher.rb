$: << File.expand_path(File.dirname(__FILE__) + "/")

require 'parse-cron'
require "lib/data/connection.rb"
require 'logger'
require 'lib/migration.rb'
require 'composite_primary_keys'

%w(crontab_parser log helper change_watcher).each {|a| require "lib/helpers/#{a}"}
%w(project task).each {|a| require "lib/data/stage/#{a}"}
%w(execution_log project settings schedule project_history schedule_history event_log request).each {|a| require "lib/data/log/#{a}"}
%w(base timeline projects statistics).each {|a| require "lib/objects/#{a}"}
%w(events severity key event test livetest startedtest finishedtest slatest).each {|a| require "lib/tests/#{a}"}
%w(splunk_downloader).each {|a| require "lib/splunk/#{a}"}
%w(testcases).each {|a| require "lib/testcases/#{a}"}



module SLAWatcher

  class << self

    def connect_to_db(hostname,port,username,password,database)
      SLAWatcher::Connection.connect(hostname,port,username,password,database)
    end

    def splunk(username,password,hostname)
      SLAWatcher::SplunkDownloader.new(username,password,hostname)
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
      values.each do |value|
        SLAWatcher::Request.create(:request_id => value[:request_id])
      end

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

      slaTest = SLAWatcher::SlaTest.new(events)
      slaTest.start

      events.mail_incident
      events.mail_status
      events.save


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





  end

end