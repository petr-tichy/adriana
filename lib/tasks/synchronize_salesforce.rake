require_relative '../sla_jobs/salesforce_synchronization_job/salesforce_synchronization_job'
require_relative '../credentials_helper'

namespace :sla do
  desc 'Synchronize with Salesforce - set monitoring field for all Contracts'
  task synchronize_salesforce: [:environment] do |task|
    task_name = task.name.split(':').last
    $log_file = Rails.root.join('log', "sla_#{task_name}_#{DateTime.now.strftime('%Y%m%d%H%M%S')}.log")
    $log = Logger.new($log_file, 'daily')
    credentials = {salesforce: {}}
    %i[client_id client_secret username password security_token].each { |param| credentials[:salesforce][param] = CredentialsHelper.get("salesforce_#{param}") }
    job = SalesforceSynchronizationJob::SalesforceSynchronizationJob.new(credentials)
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