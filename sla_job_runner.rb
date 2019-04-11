#!/usr/bin/env ruby
# 1.9 adds realpath to resolve symlinks; 1.8 doesn't
# have this method, so we add it so we get resolved symlinks
# and compatibility
require 'rubygems'
require 'bundler/setup'
require 'active_record'
require 'rake'
require 'gli'
require_relative 'config/application.rb'

class SlaWrapper
  extend GLI::App
  Rails.application.load_tasks

  program_desc 'Runner for GoodData SLA checking jobs'

  desc 'Synchronize with Splunk job - downloads execution data from Splunk logs and saves them to DB'
  command :synchronize_splunk do |c|
    c.action do |global_options, options, args|
      Rake::Task['sla:synchronize_splunk'].invoke
    end
  end

  desc 'Synchronize with Salesforce job'
  command :synchronize_salesforce do |c|
    c.action do |global_options, options, args|
      Rake::Task['sla:synchronize_salesforce'].invoke
    end
  end

  desc 'Test SLA job - runs error, live, started tests - basically checking the status of monitored schedules, sending alerts to PD'
  command :test_sla do |c|
    c.action do |global_options, options, args|
      Rake::Task['sla:test_sla'].invoke
    end
  end

  desc 'Adriana sync job runner'
  command :run_next_sync_job do |c|
    c.action do |global_options, options, args|
      Rake::Task['sla:run_next_sync_job'].invoke
    end
  end

  desc 'Post migration task - run after the DB is recreated'
  command :post_migration do |c|
    c.action do |global_options, options, args|
      Rake::Task['post_migration'].invoke
    end
  end

  pre do |global, command, options, args|
    next true if command.nil?
    @running = false
    @not_delete = false
    @command = command.name

    if File.exist?("running_#{command.name}.pid")
      @running = true
      @not_delete = true
      fail "Another process for the '#{command.name}' command is running."
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
    false
  end

  exit run(ARGV)
end
