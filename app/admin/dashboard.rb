def history_records(for_current_user: false)
  relevant_tables = [CustomerHistory, ContractHistory, ProjectHistory, ScheduleHistory]
  @history_records = relevant_tables.map do |x|
    records = x.all
    records = for_current_user ? records.where(:updated_by => current_admin_user.id) : records.where.not(:updated_by => [current_admin_user.id, AdminUser.gd_technical_admin.id])
    records.order('created_at DESC').limit(10)
  end
  @history_records.flatten.sort_by(&:created_at).reverse.take(10)
end

def mutes
  @mutes = Mute.order(created_at: :desc).limit(10)
end

ActiveAdmin.register_page 'Dashboard' do
  menu :priority => 1, :label => proc{ I18n.t('active_admin.dashboard') }

  content :title => proc{ I18n.t('active_admin.dashboard') } do
    panel 'PagerDuty incidents by day' do
      render 'admin/dashboard/notification_chart', context: self
    end

    panel 'Mutes' do
      table_for mutes do
        render 'admin/mutes/index', context: self
      end
      link_to 'See all mutes', admin_mutes_path
    end

    panel 'Recent changes by me' do
      table_for history_records(for_current_user: true) do
        render 'admin/dashboard/recent_changes', context: self
      end
    end

    panel 'Recent changes by others' do
      table_for history_records do
        render 'admin/dashboard/recent_changes', context: self
      end
    end
  end
end
