class Job < ActiveRecord::Base
  self.table_name = 'job'
  has_many :job_parameters,autosave: true
  has_many :job_entities,autosave: true
  has_many :job_histories
  belongs_to :job_type
  just_define_datetime_picker :scheduled_at

  def self.default
    select("job.*,job_type.key as key,last_history.*").joins(:job_type).joins("LEFT OUTER JOIN (SELECT jh.id as job_history_id,jh.job_id,jh.status,jh.started_at,jh.finished_at FROM job_history jh WHERE NOT EXISTS (SELECT jh2.id FROM job_history jh2 WHERE jh2.job_id = jh.job_id and jh2.id > jh.id)) last_history ON last_history.job_id = job.id")
  end
end