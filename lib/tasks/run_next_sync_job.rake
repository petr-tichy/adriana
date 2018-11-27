require_relative '../sla_jobs/job_helper'
require_relative '../credentials_helper'
require 'date'

namespace :sla do
  desc 'Adriana sync job runner'
  task run_next_sync_job: [:environment] do |task|
    $log_file = Rails.root.join('log', "sla_#{task.name.split(':').last}_#{DateTime.now.strftime('%Y%m%d%H%M%S')}.log")
    $log = Logger.new($log_file, 'daily')
    credentials = {
      passman: {address: CredentialsHelper.get('passman_address'), port: CredentialsHelper.get('passman_port'), key: CredentialsHelper.get('passman_key')}
    }
    ActiveRecord::Base.establish_connection(YAML::load(File.open('config/database.yml'))[Rails.env])
    job_to_execute = Job.get_jobs_to_execute.first
    if job_to_execute.nil?
      $log.info 'There are no jobs to execute.'
      next
    end
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
      $log.error e.backtrace
      $log.close
      job_history.log = File.read($log_file)
      job_history.finished_at = DateTime.now
      job_history.status = 'ERROR'
      job_history.save
    end
    $log.info "Job ID #{job_to_execute.id} - FINISHED"
  end
end