ActiveAdmin.register Mute do
  menu :priority => 11
  permit_params :reason, :contract_id, :project_pid, :schedule_id, :admin_user_id, :disabled,
                :start_date, :start_time_hour, :start_time_minute,
                :end_date, :end_time_hour, :end_time_minute
  config.sort_order = 'created_at_desc'
  config.clear_action_items!
  actions :all, :except => :destroy

  before_create do |mute|
    if current_active_admin_user.is_basic_user? && (mute.end - mute.start).abs > 24.hours
      mute.end = mute.start + 24.hours
    end
  end

  filter :admin_user, :as => :select, :collection => AdminUser.all.order(:email).map { |x| [x.email, x.id] }
  filter :contract, :as => :select, :collection => Contract.with_direct_mutes.order(:name)
  filter :project, :as => :select, :collection => Project.with_direct_mutes.order(:name)
  filter :disabled
  filter :start
  filter :end
  filter :created_at
  filter :updated_at

  scope :all, :default => true
  scope :active
  scope :inactive

  index do
    render 'index', context: self
  end

  form do |f|
    # Displaying this to all users that can mute, but are not super-user or admin
    if current_active_admin_user.is_basic_user?
      panel 'Info' do
        text_node 'Your role allows you to mute for <b>24 hours</b>. If you need more than that, please contact Petr Tichý or Richard Nagrant.'.html_safe
      end
    end
    f.semantic_errors *f.object.errors.keys
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

  action_item :edit, :if => proc { mute.now_in_range? }, :only => :show do
    link_to 'Edit Mute', edit_admin_mute_path(mute) if authorized? :edit, mute
  end

  action_item :recreate, :if => proc { authorized? :create, Mute }, :only => :show do
    link_to 'Recreate Mute', new_admin_mute_path(:reference_id => mute.reference_id, :reference_type => mute.reference_type, :reason => URI.escape(mute.reason)) if authorized?(:create, Mute)
  end

  member_action :disable, :if => proc { mute.now_in_range? }, :method => :get do
    @mute = Mute.find_by_id(params['id'])
    @mute.disabled = true
    @mute.save
    redirect_to admin_mutes_path, :notice => "Mute ##{@mute.id} disabled."
  end

  member_action :enable, :if => proc { mute.now_in_range? }, :method => :get do
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
      @mute.reason = URI.unescape(params['reason']) if params.key?('reason')
      @mute.start = DateTime.now
      @mute.end = DateTime.now + 1.hour
      @mute
    end
  end
end
