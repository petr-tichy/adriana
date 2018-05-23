ActiveAdmin.register ErrorFilter do
  menu :priority => 10
  config.sort_order = 'created_at_desc'
  actions :all

  index do
    column :active do |error_filter|
      error_filter.active? ? image_tag('true_icon.png', :size => '28x20') : image_tag('false_icon.png', :size => '20x20')
    end
    column :message
    column :created_by do |error_filter|
      error_filter.admin_user ? link_to(error_filter.admin_user.email, admin_admin_user_path(error_filter.admin_user)) : 'User missing'
    end
    column :actions do |error_filter|
      error_filter.active? ? link_to('Disable', disable_admin_error_filter_path(error_filter.id)) : link_to('Enable', enable_admin_error_filter_path(error_filter.id))
    end
    actions
  end


  form do |f|
    f.form_buffers.last << Arbre::Context.new{
      ul f.object.errors[:base], class: 'errors' if f.object.errors[:base].any?
    }
    f.inputs "Error filter" do
      f.input :message
      f.input :active, :as => :select, :label => 'Is filter enabled?', :include_blank => false
    end
    f.input :admin_user_id, :as => :hidden
    f.actions
  end

  show do
    panel ("General") do
      attributes_table_for error_filter do
        row :message
        row :active do |error_filter|
          error_filter.active? ? image_tag('true_icon.png', :size => '28x20') : image_tag('false_icon.png', :size => '20x20')
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
