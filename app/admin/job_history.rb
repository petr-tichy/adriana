ActiveAdmin.register JobHistory do
  menu false
  permit_params :job_id, :started_at, :finished_at, :status, :log
end