require_relative '../sla_jobs/splunk_synchronization_job/splunk_synchronization_job'
require_relative '../credentials_helper'

namespace :sla do
  desc 'Synchronize with Splunk job - downloads execution data from Splunk logs and saves them to DB'
  task synchronize_splunk: [:environment] do |task|
    $log_file = Rails.root.join('log', "sla_#{task.name.split(':').last}.log")
    $log = Logger.new($log_file, 'daily')
    credentials = {
      passman: {address: CredentialsHelper.get('passman_address'), port: CredentialsHelper.get('passman_port'), key: CredentialsHelper.get('passman_key')},
      splunk: {username: CredentialsHelper.get('splunk_username'), hostname: CredentialsHelper.get('splunk_hostname') }
    }
    job = SplunkSynchronizationJob::SplunkSynchronizationJob.new(credentials)
    job.connect
    job.run
  end
end