ActiveAdmin.register ProjectHistory do
  menu false
  permit_params :project_pid, :key, :value, :valid_from, :valid_to, :updated_by
end