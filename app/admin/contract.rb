ActiveAdmin.register Contract do
  menu :priority => 8, :parent => 'Resources'
  permit_params :name

  filter :customer, :as => :select, :collection => Customer.all.order(:name)
  %i[ name created_at updated_at is_deleted
      sla_enabled monitoring_enabled contract_type token
  ].each { |x| filter x }

  scope :all, :default => true
  scope :not_muted
  scope :muted

  index row_class: ->(c) { 'row-highlight-muted' if c.muted? } do
    selectable_column
    column :name do |contract|
      link_to contract.name, admin_contract_path(contract)
    end
    column :customer do |contract|
      link_to contract.customer.name, admin_customer_path(contract.customer)
    end
    column :sla_enabled
    column :sla_type
    column :monitoring_enabled
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
      f.input :monitoring_enabled
      f.input :monitoring_emails
      f.input :monitoring_treshhold
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
      f.li "<label class='label'>Schedules</label><span class='action input_action'>#{link_to('Update max error count for all related schedules', {:controller => 'contracts', :action => 'error_show'}, { :class => 'button' })}</span>".html_safe
      f.link_to 'Update Max Error Count for Schedules', :controller => 'contracts', :action => 'error_show'
    end
    f.inputs 'Customer' do
      f.input :customer, :as => :select2, :collection => Customer.all.order(:name)
    end
    f.inputs 'SLA' do
      f.input :sla_enabled
      f.input :sla_type
      f.input :sla_value
      f.input :sla_percentage
    end
    f.actions
  end


  show do
    if contract.muted?
      panel('Contract is muted', class: 'panel-muted') do
        span do
          text_node 'This contract is currently muted, no notifications will be sent to PagerDuty. Here are the relevant mutes:'
        end
        table_for contract.all_mutes do
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

      column do
        panel('Monitoring') do
          attributes_table_for contract do
            row :monitoring_enabled, :label => 'Monitoring Enabled'
            row :monitoring_emails, :label => 'Monitoring Emails'
            row :monitoring_treshhold, :label => 'Monitoring Treshhold'

          end
        end
        panel('SLA') do
          attributes_table_for contract do
            row :sla_enabled
            row :sla_type
            row :sla_value
            row :sla_percentage
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

  action_item :update_max_error_count, :only => %i[show edit] do
    link_to 'Update Max Error Count for Schedules', :controller => 'contracts', :action => 'error_show'
  end

  action_item :create_sync_job, :only => %i[show] do
    link_to 'Create synchronization job', :controller => 'jobs', :action => 'new', :type => 'synchronize_contract', :contract => contract.id
  end

  controller do
    #layout 'active_admin',  :only => [:new]
    include ApplicationHelper

    def scoped_collection
      end_of_association_chain.default
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


    before_action :only => [:index] do
      params['q'] = {:is_deleted_eq => '0'} if params['commit'].blank?
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
        @contract.name = params[:contract]['name']
        @contract.customer_id = params[:contract]['customer_id']
        @contract.sla_enabled = params[:contract]['sla_enabled']
        @contract.sla_type = params[:contract]['sla_type']
        @contract.sla_value = params[:contract]['sla_value']
        @contract.sla_percentage = params[:contract]['sla_percentage']
        @contract.monitoring_enabled = params[:contract]['monitoring_enabled']
        @contract.monitoring_treshhold = params[:contract]['monitoring_treshhold']
        @contract.contract_type = params[:contract]['contract_type']
        if @contract.save
          public_attributes.each do |attr|
            unless same?(params[:contract][attr], @contract[attr])
              ContractHistory.add_change(@contract.id, attr, params[:contract][attr].to_s, current_active_admin_user)
            end
          end
          redirect_to admin_contract_path(@contract.id), :notice => 'Contract was created!'
        else
          flash[:error] = 'Please review the errors below.'
          render action: 'new'
        end
      end
    end

    def destroy
      ActiveRecord::Base.transaction do
        Contract.mark_deleted(params[:id], current_active_admin_user)
      end
      redirect_to admin_contracts_path, :notice => 'Contract was deleted!'
    end

    def autocomplete_tags
      @tags = ActsAsTaggableOn::Tag.where('name LIKE ?', "#{params[:q]}%").order(:name)
      respond_to do |format|
        format.json { render json: @tags, only: %i[id name] }
      end
    end
  end
end