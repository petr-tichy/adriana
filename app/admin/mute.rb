ActiveAdmin.register Mute do
  menu :priority => 9, :parent => 'Resources'
  permit_params :reason, :contract_id, :project_pid, :schedule_id, :admin_user_id, :disabled,
                :start_date, :start_time_hour, :start_time_minute,
                :end_date, :end_time_hour, :end_time_minute
  config.sort_order = 'created_at_desc'
  config.clear_action_items!
  actions :all, :except => :destroy

  preserve_default_filters!
  filter :admin_user, :as => :select, :collection => AdminUser.all.order(:email).map { |x| [x.email, x.id] }
  filter :contract, :as => :select, :collection => Contract.all.order(:name)
  filter :active, :as => :select, :label => 'Active?', :collection => [['Active', :active], ['Inactive', :inactive]]

  index row_class: ->(m) { 'row-highlight-muted' if m.active? } do
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


  form do |f|
    f.inputs 'Mute' do
      f.input :start, :as => :just_datetime_picker
      f.input :end, :as => :just_datetime_picker
      f.input :disabled, :as => :select, :label => 'Disable the mute for now?', :include_blank => false
      f.input :reason, :label => 'Provide a reason for muting'
      f.input :contract_id, :as => :hidden
      f.input :project_pid, :as => :hidden
      f.input :schedule_id, :as => :hidden
      f.input :admin_user_id, :as => :hidden
    end
    f.actions
  end

  show do
    panel('General') do
      attributes_table_for mute do
        row :reason
        row :disabled
        row :admin_user
        row :muted_object_type do |mute|
          obj = mute.contract || mute.project || mute.schedule
          obj.class.name
        end
        row :muted_object do |mute|
          obj = mute.contract || mute.project || mute.schedule
          link_to obj.name, polymorphic_path(['admin', obj])
        end
        row :active do |mute|
          status_tag mute.active?
        end
        row :created_at
        row :updated_at
      end
    end
    panel('Duration') do
      attributes_table_for mute do
        row :start
        row :end
      end
    end
  end

  member_action :disable, :method => :get do
    @mute = Mute.find_by_id(params['id'])
    @mute.disabled = true
    @mute.save
    redirect_to admin_mutes_path, :notice => "Mute ##{@mute.id} disabled."
  end

  member_action :enable, :method => :get do
    @mute = Mute.find_by_id(params['id'])
    @mute.disabled = false
    @mute.save
    redirect_to admin_mutes_path, :notice => "Mute ##{@mute.id} enabled."
  end

  controller do
    include ApplicationHelper

    def scoped_collection
      if params.key? 'mute_ids'
        end_of_association_chain.where(id: params['mute_ids'])
      else
        end_of_association_chain
      end
    end

    def new
      @mute = Mute.new
      class_name = params['reference_type']
      class_name_under = class_name.underscore
      return nil unless %w[contract project schedule].include?(class_name_under)
      @mute.send("#{class_name_under}=".to_sym, class_name.constantize.find(params['reference_id']))
      @mute.admin_user = current_active_admin_user
      @mute
    end
  end
end
