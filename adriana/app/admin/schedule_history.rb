ActiveAdmin.register ScheduleHistory do
  menu false
  permit_params :schedule_id, :key, :value, :valid_from, :valid_to, :updated_by
end