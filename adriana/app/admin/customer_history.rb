ActiveAdmin.register CustomerHistory do
  menu false
  permit_params :customer_id, :key, :value, :valid_from, :valid_to, :updated_by
end