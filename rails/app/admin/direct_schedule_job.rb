ActiveAdmin.register DirectScheduleJob do
  menu false
  permit_params :job_type_id, :scheduled_by, :recurrent, :scheduled_at
end