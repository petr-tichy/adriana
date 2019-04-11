require_relative '../sla_jobs/job_helper'
require_relative '../credentials_helper'
require 'date'

namespace :sla do
  desc 'Adriana sync job runner'
  task run_next_sync_job: [:environment] do |task|
    task_name = task.name.split(':').last
    $log_file = Rails.root.join('log', "sla_#{task_name}_#{DateTime.now.strftime('%Y%m%d%H%M%S')}.log")
    $log = Logger.new($log_file, 'daily')
    credentials = {passman: {}}
    %i[address port key].each do |param|
      credentials[:passman][param] = CredentialsHelper.get("passman_#{param}")
    end
    ActiveRecord::Base.establish_connection(YAML::load(File.open('config/database.yml'))[Rails.env])
    job_to_execute = Job.get_jobs_to_execute.first
    if job_to_execute.nil?
      $log.info 'There are no jobs to execute.'
      next
    end
    job_id = job_to_execute.id
    $log.info "SLA Sync Job with ID #{job_id} - STARTED"
    job_class = JobHelper.get_job_by_name(job_to_execute.job_type.key)
    job = job_class.new(job_id, credentials)
    begin
      job_history = JobHistory.create(:job_id => job_id, :started_at => DateTime.now, :status => 'RUNNING')
      job.connect if job.respond_to?(:connect)
      job.run
      $log.info "SLA Sync Job with ID #{job_to_execute.id} - FINISHED"
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
      raise e
    end
  end
end