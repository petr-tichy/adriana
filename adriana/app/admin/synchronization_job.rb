ActiveAdmin.register SynchronizationJob do
  menu false
  permit_params :job_type_id, :scheduled_by, :recurrent, :scheduled_at, :cron
end