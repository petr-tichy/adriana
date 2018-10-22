ActiveAdmin.register JobParameter do
  menu false
  permit_params :job_id, :key, :value
end