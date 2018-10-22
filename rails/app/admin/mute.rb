ActiveAdmin.register Mute do
  menu :priority => 9
  permit_params :reason, :contract_id, :project_pid, :schedule_id, :admin_user_id, :disabled,
                :start_date, :start_time_hour, :start_time_minute,
                :end_date, :end_time_hour, :end_time_minute
  config.sort_order = 'created_at_desc'
  config.clear_action_items!
  actions :all, :except => :destroy

  index do
    column :active do |mute|
      mute.active? ? image_tag('true_icon.png', :size => '28x20') : image_tag('false_icon.png', :size => '20x20')
    end
    column :reason
    column :start
    column :end
    column :muted_object do |mute|
      obj = mute.contract || mute.project || mute.schedule
      link_to obj.name, polymorphic_path(['admin', obj])
    end
    column :created_by do |mute|
      mute.admin_user ? link_to(mute.admin_user.email, admin_admin_user_path(mute.admin_user)) : 'User missing'
    end
    column :actions do |mute|
      mute.disabled? ? link_to('Enable', enable_admin_mute_path(mute.id)) : link_to('Disable', disable_admin_mute_path(mute.id))
    end
    actions
  end


  form do |f|
    f.inputs "Mute" do
      f.input :reason
      f.input :start, :as => :just_datetime_picker
      f.input :end, :as => :just_datetime_picker
      f.input :disabled, :as => :select, :label => 'Disable mute?', :include_blank => false
      f.input :contract_id, :as => :hidden
      f.input :project_pid, :as => :hidden
      f.input :schedule_id, :as => :hidden
      f.input :admin_user_id, :as => :hidden
    end
    f.actions
  end

  show do
    panel ("General") do
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
          mute.active? ? image_tag('true_icon.png', :size => '28x20') : image_tag('false_icon.png', :size => '20x20')
        end
        row :created_at
        row :updated_at
      end
    end
    panel ("Duration") do
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
      return nil unless %w(contract project schedule).include?(class_name_under)
      @mute.send("#{class_name_under}=".to_sym, class_name.constantize.find(params['reference_id']))
      @mute.admin_user = current_active_admin_user
      @mute
    end
  end
end
