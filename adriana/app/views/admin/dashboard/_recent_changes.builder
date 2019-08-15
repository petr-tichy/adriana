context.instance_eval do
  column :related_record
  column :key
  column :value
  column(:updated_by) do |c|
    AdminUser.find_by_id(c.updated_by)&.email || '-'
  end
  column :created_at
end