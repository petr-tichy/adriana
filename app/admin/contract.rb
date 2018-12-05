ActiveAdmin.register Contract do
  menu :priority => 8, :parent => 'Resources'
  permit_params :name

  filter :customer, :as => :select, :collection => Customer.with_contracts.order(:name)
  %i[ name created_at updated_at contract_type token].each { |x| filter x }
  filter :is_deleted, as: :check_boxes

  scope :all, :default => true
  scope :not_muted
  scope :muted

  index(row_class: lambda do |c|
    x = []
    x << 'row-highlight-muted' if c.muted?
    x << 'row-highlight-deleted' if c.is_deleted
    x.join(' ')
  end) do
    selectable_column
    column :name do |contract|
      link_to contract.name, admin_contract_path(contract)
    end
    column :customer do |contract|
      link_to contract.customer.name, admin_customer_path(contract.customer)
    end
    column 'Muted?' do |contract|
      elements = ''
      status_tag contract.muted?
      if contract.muted?
        elements += link_to 'Mutes list', admin_mutes_path('q[contract_id_eq]' => contract.id.to_s.html_safe, 'commit' => 'Filter')
      else
        elements += link_to 'Mute', new_admin_mute_path(:reference_id => contract.send(Contract.primary_key.to_sym), :reference_type => Contract.name)
      end
      elements.html_safe
    end
    column :actions do |contract|
      link_to 'Create synchronization job', :controller => 'jobs', :action => 'new', :type => 'synchronize_contract', :contract => contract.id
    end
    column :links do |contract|
      links = ''.html_safe
      links += link_to 'Projects', admin_projects_path('q[contract_id_eq]' => contract.id.to_s.html_safe, 'commit' => 'Filter')
      links += ' '
      links += link_to 'Schedules', admin_schedules_path('q[contract_id_eq]' => contract.id.to_s.html_safe, 'commit' => 'Filter')
      links
    end
  end

  form do |f|
    f.inputs 'Contract' do
      f.input :name
      f.input :customer_id, :as => :hidden
      f.input :token
      f.input :documentation_url
      f.input :tag_list,
              label: 'Tags',
              input_html: {
                data: {
                  placeholder: 'Enter tags',
                  saved: f.object.tags.map { |t| {id: t.name, name: t.name} }.to_json,
                  url: autocomplete_tags_path},
                class: 'tagselect'
              }
      f.input :contract_type, :as => :select, :collection => %w[ direct poweredby N/A ]
    end
    f.inputs 'Max number of errors' do
      f.input :default_max_number_of_errors, :default => 0
      unless f.object.new_record?
        f.li "<label class='label'>Schedules</label><span class='action input_action'>#{link_to('Update max error count for all related schedules', {:controller => 'contracts', :action => 'error_show'}, { :class => 'button' })}</span>".html_safe
      end
      end
    f.inputs 'Customer' do
      f.input :customer, :as => :select2, :collection => Customer.all.order(:name)
    end
    f.actions
  end


  show do
    if contract.muted?
      panel('Contract is muted', class: 'panel-muted') do
        span do
          text_node 'This contract is currently muted, no notifications will be sent to PagerDuty. Here are the relevant mutes:'
        end
        table_for contract.active_mutes do
          column :id do |mute|
            link_to mute.id, admin_mute_path(mute)
          end
          column :reason
          column :start
          column :end
          column :admin_user, :label => 'Muted by'
        end
      end
    end
    columns do
      column do
        panel('General') do
          attributes_table_for contract do
            row :name
            row :customer do |contract|
              customer = Customer.find_by_id(contract.customer_id)
              link_to customer.name, :controller => 'customers', :action => 'show', :id => customer.id
            end
            row :updated_at
            row :created_at
            row :is_deleted
            row :tag_list
            row :token
            row :documentation_url
            row :default_max_number_of_errors
            row :contract_type
          end
        end
      end
    end
    panel('History') do
      table_for ContractHistory.where('contract_id = ?', params['id']).order('id DESC').limit(10) do
        column(:key)
        column(:value)
        column(:updated_by) do |c|
          AdminUser.find_by_id(c.updated_by)&.email || '-'
        end
        column(:created_at)
      end
    end
  end

  config.clear_action_items!

  action_item :mute, only: :show do
    link_to 'Mute', new_admin_mute_path(:reference_id => contract.send(Contract.primary_key.to_sym), :reference_type => Contract.name) if authorized? :create, Mute
  end

  action_item :edit, only: :show do
    link_to 'Edit Contract', edit_admin_contract_path(contract) if authorized? :edit, contract
  end

  action_item :destroy, only: :show do
    link_to contract.is_deleted ? 'Un-delete Contract' : 'Delete Contract', admin_contract_path(contract), :method => :delete if authorized? :destroy, contract
  end

  action_item :update_max_error_count, :only => %i[show edit] do
    link_to 'Update Max Error Count for Schedules', :controller => 'contracts', :action => 'error_show' if authorized? :edit, Schedule
  end

  action_item :create_sync_job, :only => %i[show] do
    link_to 'Create synchronization job', :controller => 'jobs', :action => 'new', :type => 'synchronize_contract', :contract => contract.id if authorized? :create, Job
  end

  controller do
    include ApplicationHelper

    before_filter :only => [:index] do
      if params['commit'].blank? && params['q'].blank?
        params['q'] = {:is_deleted_in => false}
      end
    end

    def scoped_collection
      end_of_association_chain
    end

    def error_show
      @contract = Contract.find_by_id(params['id'])
      render 'admin/contracts/update_error_contract'
    end

    def error_modification
      schedules = Schedule.joins(:project).joins(:contract).where(contract: {id: params['contract']['id']})
      ActiveRecord::Base.transaction do
        schedules.update_all(max_number_of_errors: params['contract']['max_number_of_errors'])
        ScheduleHistory.mass_add_change(schedules, 'max_number_of_errors', params['contract']['max_number_of_errors'], current_active_admin_user)
      end
      redirect_to admin_contract_path(params['contract']['id']), :notice => 'Max number of errors was updated.'
    end

    def update
      @contract = Contract.where('id = ?', params[:id]).first
      public_attributes = Contract.get_public_attributes
      ActiveRecord::Base.transaction do
        public_attributes.each do |attr|
          unless same?(params[:contract][attr], @contract[attr])
            ContractHistory.add_change(@contract.id, attr, params[:contract][attr].to_s, current_active_admin_user)
            @contract[attr] = params[:contract][attr]
          end
        end
        @contract.tag_list = params['contract']['tag_list']
        if @contract.save
          redirect_to admin_contract_path(params[:id]), :notice => 'Contract was updated!'
        else
          flash[:error] = 'Please review the errors below.'
          render action: 'edit'
        end
      end
    end

    def new
      @contract = Contract.new
      @contract.customer_id = params['customer_id']
      new!
    end

    def create
      public_attributes = Contract.get_public_attributes
      @contract = nil
      ActiveRecord::Base.transaction do
        @contract = Contract.new
        @contract.customer_id = params[:contract]['customer_id']
        public_attributes.each do |attr|
          @contract[attr] = params[:contract][attr]
        end
        if @contract.save
          redirect_to admin_contract_path(@contract.id), :notice => 'Contract was created!'
        else
          flash[:error] = 'Please review the errors below.'
          render action: 'new'
        end
      end
    end

    def destroy
      id = params[:id]
      contract = Contract.find_by_id(id)
      if contract.is_deleted
        ActiveRecord::Base.transaction do
          Contract.mark_deleted(id, current_active_admin_user, flag: false)
        end
        redirect_to admin_contracts_path, :notice => 'Contract was un-deleted!'
      else
        ActiveRecord::Base.transaction do
          Contract.mark_deleted(id, current_active_admin_user, flag: true)
        end
        redirect_to admin_contracts_path, :notice => 'Contract was deleted!'
      end
    end

    def autocomplete_tags
      @tags = ActsAsTaggableOn::Tag.where('name LIKE ?', "#{params[:q]}%").order(:name)
      respond_to do |format|
        format.json { render json: @tags, only: %i[id name] }
      end
    end
  end
end