require_relative '../sla_jobs/splunk_synchronization_job/splunk_synchronization_job'
require_relative '../credentials_helper'

namespace :sla do
  desc 'Synchronize with Splunk job - downloads execution data from Splunk logs and saves them to DB'
  task synchronize_splunk: [:environment] do |task|
    task_name = task.name.split(':').last
    $log_file = Rails.root.join('log', "sla_#{task_name}_#{DateTime.now.strftime('%Y%m%d%H%M%S')}.log")
    $log = Logger.new($log_file, 'daily')
    credentials = {
      passman: {},
      splunk: {}
    }
    %i[address port key].each { |param| credentials[:passman][param] = CredentialsHelper.get("passman_#{param}") }
    %i[username hostname].each { |param| credentials[:splunk][param] = CredentialsHelper.get("splunk_#{param}") }
    job = SplunkSynchronizationJob::SplunkSynchronizationJob.new(credentials)
    begin
      job.connect
      job.run
      $log.info "SLA Job #{task_name} - FINISHED"
      $log.close
    rescue JobException, StandardError => e
      $log.error e.message
      $log.error e.backtrace
      $log.close
      raise e
    end
  end
end