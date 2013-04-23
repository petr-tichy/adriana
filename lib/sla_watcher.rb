$: << File.expand_path(File.dirname(__FILE__) + "/")

require 'parse-cron'
require "lib/data/connection.rb"
require 'logger'

%w(crontab_parser log helper).each {|a| require "lib/helpers/#{a}"}
%w(execution_log project_info project settings).each {|a| require "lib/data/#{a}"}
%w(base timeline projects statistics).each {|a| require "lib/objects/#{a}"}
%w(splunk_downloader).each {|a| require "lib/splunk/#{a}"}


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


    def load_last_run
      Helper.value_to_datetime(SLAWatcher::Settings.load_last_splunk_synchronization.first.value)
    end

    def save_last_run(time)
      SLAWatcher::Settings.save_last_splunk_synchronization(time)
    end


    def log_execution(pid,graph_name,mode,status,detailed_status,time = nil)
      SLAWatcher::ExecutionLog.log_execution(pid,graph_name,mode,status,detailed_status,time)
    end



  end

end