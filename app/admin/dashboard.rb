def history_records(for_current_user = false)
  relevant_tables = [CustomerHistory, ContractHistory, ProjectHistory, ScheduleHistory]
  @history_records = relevant_tables.map do |x|
    records = x.all
    records = for_current_user ? records.where(:updated_by => current_admin_user.id) : records.where.not(:updated_by => current_admin_user.id)
    records.order('created_at DESC').limit(10)
  end
  @history_records.flatten.sort_by(&:created_at).reverse.take(10)
end

def mutes
  @mutes = Mute.active
end

ActiveAdmin.register_page 'Dashboard' do
  menu :priority => 1, :label => proc{ I18n.t('active_admin.dashboard') }

  content :title => proc{ I18n.t('active_admin.dashboard') } do
    panel 'Overview' do
      render 'overview'
    end

    panel 'Active mutes' do
      if mutes.any?
        table_for mutes do
          column :detail do |mute|
            link_to 'Detail', admin_mute_path(mute)
          end
          column :active, &:active?
          column :reason
          column :start
          column :end
          column :muted_object_type
          column :muted_object do |mute|
            obj = mute.contract || mute.project || mute.schedule
            link_to obj.name, polymorphic_path(['admin', obj])
          end
          column :created_by do |mute|
            mute.admin_user ? link_to(mute.admin_user.email, admin_admin_user_path(mute.admin_user)) : 'User missing'
          end
          column :disabled do |mute|
            status_tag mute.disabled
            mute.disabled? ? link_to('Enable', enable_admin_mute_path(mute.id)) : link_to('Disable', disable_admin_mute_path(mute.id))
          end
        end
      else
        'There are currently no active mutes.'
      end
    end

    panel 'Recent changes by me' do
      table_for history_records(true) do
        column :related_record
        column :key
        column :value
        column(:updated_by) do |c|
          AdminUser.find_by_id(c.updated_by)&.email || '-'
        end
        column :created_at
      end
    end

    panel 'Recent changes by others' do
      table_for history_records do
        column :related_record
        column :key
        column :value
        column(:updated_by) do |c|
          AdminUser.find_by_id(c.updated_by)&.email || '-'
        end
        column :created_at
      end
    end
  end
end
