ActiveAdmin.register ErrorFilter do
  menu :priority => 10, :parent => 'Custom actions'
  permit_params :message, :admin_user_id, :active
  config.sort_order = 'created_at_desc'
  actions :all

  index do
    column :detail do |error_filter|
      link_to 'Detail', admin_error_filter_path(error_filter)
    end
    column :active do |error_filter|
      status_tag error_filter.active?
    end
    column :message
    column :created_by do |error_filter|
      error_filter.admin_user ? link_to(error_filter.admin_user.email, admin_admin_user_path(error_filter.admin_user)) : 'User missing'
    end
    column :actions do |error_filter|
      error_filter.active? ? link_to('Disable', disable_admin_error_filter_path(error_filter.id)) : link_to('Enable', enable_admin_error_filter_path(error_filter.id))
    end
  end

  form do |f|
    f.inputs 'Error filter' do
      f.input :message
      f.input :active, :as => :select, :label => 'Is filter enabled?', :include_blank => false
    end
    f.input :admin_user_id, :as => :hidden
    f.actions
  end

  show do
    panel 'General' do
      attributes_table_for error_filter do
        row :message
        row :active do |error_filter|
          status_tag error_filter.active?
        end
        row :admin_user
        row :created_at
        row :updated_at
      end
    end
  end

  member_action :disable, :method => :get do
    @error_filter = ErrorFilter.find_by_id(params['id'])
    @error_filter.active = false
    @error_filter.save
    redirect_to admin_error_filters_path, :notice => "Error filter ##{@error_filter.id} disabled."
  end

  member_action :enable, :method => :get do
    @error_filter = ErrorFilter.find_by_id(params['id'])
    @error_filter.active = true
    @error_filter.save
    redirect_to admin_error_filters_path, :notice => "Error filter ##{@error_filter.id} enabled."
  end

  controller do
    include ApplicationHelper

    def scoped_collection
      if params.key? 'error_filter_ids'
        end_of_association_chain.where(id: params['error_filter_ids'])
      else
        end_of_association_chain
      end
    end

    def new
      @error_filter = ErrorFilter.new
      @error_filter.admin_user = current_active_admin_user
      @error_filter
    end
  end
end
