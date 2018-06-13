ActiveAdmin.register JobEntity do
  menu false
  permit_params :job_id, :status, :r_schedule, :r_project, :r_customer, :r_contract, :r_settings_server
end