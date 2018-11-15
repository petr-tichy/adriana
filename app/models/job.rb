class Job < ActiveRecord::Base
  self.table_name = 'job'
  has_many :job_parameters, autosave: true
  has_many :job_entities, autosave: true
  has_many :job_histories
  belongs_to :job_type
  just_define_datetime_picker :scheduled_at

  attr_accessor :next_run

  def self.default
    select('job.*,job_type.key as key,last_history.*').joins(:job_type).joins('LEFT OUTER JOIN (SELECT jh.id as job_history_id,jh.job_id,jh.status,jh.started_at,jh.finished_at FROM job_history jh WHERE NOT EXISTS (SELECT jh2.id FROM job_history jh2 WHERE jh2.job_id = jh.job_id and jh2.id > jh.id)) last_history ON last_history.job_id = job.id')
  end

  def self.get_jobs_to_execute
    job_histories = JobHistory.where('NOT EXISTS (SELECT jh.id FROM job_history jh WHERE jh.job_id = job_history.job_id and jh.id > job_history.id)')
    jobs = Job.joins(:job_type)
    now = DateTime.now.utc
    jobs_to_run = jobs.to_a.delete_if do |job|
      next true if job.scheduled_at.utc > DateTime.now.utc

      job_history = job_histories.find { |jh| jh.job_id == job.id }
      last_run = !job_history.nil? ? job_history.started_at.utc : job.created_at.utc
      # Lets check recurrent jobs
      if job.recurrent
        next_run = Executor::Helper.next_run(job.cron, last_run, Executor::UTCTime)
        if next_run <= now && (job_history.nil? || job_history.status != 'RUNNING')
          job.scheduled_at = next_run
          next false
        end
      elsif job_history.nil? && job.scheduled_at < now
        next false
      end
      true
    end

    jobs_to_run.sort! { |a, b| a.scheduled_at <=> b.scheduled_at }
    jobs_to_run
  end
end