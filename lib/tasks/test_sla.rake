require_relative '../sla_jobs/test_job/test_job'
require_relative '../credentials_helper'

namespace :sla do
  desc 'Test job - runs error, live, started tests - basically checking the status of monitored schedules, sending alerts to PD'
  task test_sla: [:environment] do |task|
    $log_file = Rails.root.join('log', "sla_#{task.name.split(':').last}.log")
    $log = Logger.new($log_file, 'daily')
    credentials = {
      pager_duty: {api_key: CredentialsHelper.get('pd_api_key'), subdomain: CredentialsHelper.get('pd_subdomain')}
    }
    job = TestJob::TestJob.new(credentials, CredentialsHelper.get('l2_pd_service'), CredentialsHelper.get('ms_pd_service'))
    job.connect
    job.run
  end
end
