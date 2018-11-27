#!/usr/bin/env ruby
# 1.9 adds realpath to resolve symlinks; 1.8 doesn't
# have this method, so we add it so we get resolved symlinks
# and compatibility
require 'rubygems'
require 'bundler/setup'
require 'active_record'
require 'gli'
require 'json'
require 'yaml'
require_relative 'lib/sla_jobs/job_helper'
require_relative 'lib/sla_jobs/splunk_synchronization_job/splunk_synchronization_job'
require_relative 'lib/sla_jobs/test_job/test_job'
require_relative 'app/models/job_history'
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

desc 'Adriana sync job runner'
command :run_next_sync_job do |c|
  c.action do |global_options, options, args|
    credentials = {
      passman: {address: @passman_address, port: @passman_port, key: @passman_key}
    }
    ActiveRecord::Base.establish_connection(YAML::load(File.open('config/database.yml'))[Rails.env])
    job_to_execute = Job.get_jobs_to_execute.first
    job_id = job_to_execute.id
    $log.info "Job ID #{job_id} - STARTED"
    job_class = JobHelper.get_job_by_name(job_to_execute.job_type.key)
    job = job_class.new(job_id, credentials)
    begin
      job_history = JobHistory.create(:job_id => job_id, :started_at => DateTime.now, :status => 'RUNNING')
      job.connect if job.respond_to?(:connect)
      job.run
      $log.close
      job_history.log = File.read($log_file)
      job_history.finished_at = DateTime.now
      job_history.status = 'FINISHED'
      job_history.save
    rescue JobException, StandardError => e
      $log.error e.message
      $log.close
      job_history.log = File.read($log_file)
      job_history.finished_at = DateTime.now
      job_history.status = 'ERROR'
      job_history.save
    end
    $log.info "Job ID #{job_to_execute.id} - FINISHED"
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
    @passman_address = json['passman_address']
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
  $log.error exception.backtrace
  if exception.is_a?(SystemExit) && exception.status.zero?
  else
    $log.error exception.inspect
  end
  false
end

exit run(ARGV)
