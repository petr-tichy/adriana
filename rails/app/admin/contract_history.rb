ActiveAdmin.register ContractHistory do
  menu false
  permit_params :contract_id, :key, :value, :valid_from, :valid_to, :updated_by
end