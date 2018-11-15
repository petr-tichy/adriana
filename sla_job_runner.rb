#!/usr/bin/env ruby
# 1.9 adds realpath to resolve symlinks; 1.8 doesn't
# have this method, so we add it so we get resolved symlinks
# and compatibility
require 'rubygems'
require 'bundler/setup'
require 'active_record'
require 'gli'
require 'json'
require_relative 'sla_jobs/splunk_synchronization_job/splunk_synchronization_job'
require_relative 'sla_jobs/contract_synchronization_job/contract_synchronization_job'
require_relative 'sla_jobs/test_job/test_job'
require 'require_all'
require_rel '../../app/models'

include GLI::App

program_desc 'Runner for GoodData SLA checking jobs'

desc 'Synchronize with Splunk job - downloads execution data from Splunk logs and saves them to DB'
command :splunk_synchronization do |c|
  c.action do |global_options, options, args|
    credentials = {
      passman: {address: @passman_address, port: @passman_port, key: @passman_key},
      splunk: {username: @splunk_username, hostname: @splunk_hostname}
    }
    job = SplunkSynchronizationJob::SplunkSynchronizationJob.new(credentials)
    job.connect
    job.run
  end
end

desc 'Test job - runs error, live, started tests - basically checking the status of monitored schedules, sending alerts to PD'
command :test do |c|
  c.action do |global_options, options, args|
    credentials = {
      pager_duty: {api_key: @pd_api_key, subdomain: @pd_subdomain}
    }
    job = TestJob::TestJob.new(credentials, @pd_service[:l2], @pd_service[:ms])
    job.connect
    job.run
  end
end

pre do |global, command, options, args|
  next true if command.nil?
  @running = false
  @not_delete = false
  @command = command.name
  $log = Logger.new("log/sla_#{command.name}.log", 'daily')

  File.open('config/config.json', 'r') do |f|
    json = JSON.load(f)
    @splunk_username = json['splunk_username']
    @splunk_password = json['splunk_password']
    @splunk_hostname = json['splunk_hostname']
    @postgres_hostname = json['postgres_hostname']
    @postgres_port = json['postgres_port']
    @postgres_username = json['postgres_username']
    @postgres_password = json['postgres_password']
    @postgres_database = json['postgres_database']
    @google_username = json['google_username']
    @google_password = json['google_password']
    @passman_address = json['passman_adress']
    @passman_port = json['passman_port']
    @passman_key = json['passman_key']
    @pd_api_key = json['pd_api_key']
    @pd_subdomain = json['pd_subdomain']
    @pd_service = {l2: json['l2_pd_service'], ms: json['ms_pd_service']}
  end

  if File.exist?("running_#{command.name}.pid")
    @running = true
    @not_delete = true
    exit_now! 'Another process for this command is running'
  end
  FileUtils.touch("running_#{command.name}.pid")
  # Return true to proceed; false to abort and not call the chosen command
  true
end

post do |global, command, options, args|
  FileUtils.rm_f("running_#{command.name}.pid") unless @running
end

on_error do |exception|
  FileUtils.rm_f("running_#{@command}.pid") unless @not_delete
  pp exception.backtrace
  if exception.is_a?(SystemExit) && exception.status == 0
    false
  else
    pp exception.inspect
    false
  end
end

exit run(ARGV)
