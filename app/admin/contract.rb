ActiveAdmin.register Contract do
  menu :priority => 8
  permit_params :name
  %i( customer name created_at updated_at is_deleted
      sla_enabled sla_percentage sla_type sla_value
      monitoring_enabled contract_type token
  ).each { |x| filter x }

  index do
    column :customer_name do |contract|
      contract.customer.name
    end
    column :name
    column :sla_enabled do |contract|
      if contract.sla_enabled
        span(image_tag("true_icon.png", :size => "28x20"))
      else
        span(image_tag("false_icon.png", :size => "20x20"))
      end
    end
    column :sla_type, :label => "Sla Type"
    column :monitoring_enabled, :label => "Monitoring" do |contract|
      if contract.monitoring_enabled
        span(image_tag("true_icon.png", :size => "28x20"))
      else
        span(image_tag("false_icon.png", :size => "20x20"))
      end
    end
    column :muted do |contract|
      elements = ''
      if contract.muted?
        elements += image_tag('true_icon.png', :size => '28x20') + ' '
        elements += link_to 'Mutes list', admin_mutes_path('q[contract_id_eq]' => "#{contract.id}".html_safe, 'commit' => 'Filter')
      else
        elements += image_tag('false_icon.png', :size => '20x20') + ' '
        elements += link_to 'Mute', new_admin_mute_path(:reference_id => contract.send(Contract.primary_key.to_sym), :reference_type => Contract.name)
      end
      elements.html_safe
    end
    column :actions do |contract|
      link_to "Synchronization", :controller => "jobs", :action => "new", :type => "synchronize_contract", :contract => contract.id
    end
    column :links do |contract|
      links = ''.html_safe
      links += link_to "Projects", admin_projects_path('q[contract_id_eq]' => "#{contract.id}".html_safe, 'commit' => 'Filter')
      links += " "
      links += link_to "Schedules", admin_schedules_path('q[contract_id_eq]' => "#{contract.id}".html_safe, 'commit' => 'Filter')
      links
    end
    actions
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
      f.input :default_max_number_of_errors, :default => 0
      f.input :tag_list,
              label: "Tags",
              input_html: {
                data: {
                  placeholder: "Enter tags",
                  saved: f.object.tags.map { |t| {id: t.name, name: t.name} }.to_json,
                  url: autocomplete_tags_path},
                class: 'tagselect'
              }
      f.input :contract_type, :as => :select, :collection => %w( direct poweredby N/A )
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
    panel ("General") do
      attributes_table_for contract do
        row :name
        row :customer do |contract|
          customer = Customer.find_by_id(contract.customer_id)
          link_to customer.name, :controller => "customers", :action => "show", :id => customer.id
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
    panel ("Monitoring") do
      attributes_table_for contract do
        row :monitoring_enabled, :label => "Monitoring Enabled"
        row :monitoring_emails, :label => "Monitoring Emails"
        row :monitoring_treshhold, :label => "Monitoring Treshhold"

      end
    end
    panel ("SLA") do
      attributes_table_for contract do
        row :sla_enabled
        row :sla_type
        row :sla_value
        row :sla_percentage
      end
    end
  end

  action_item :update_max_error_count, :only => [:show, :edit] do
    link_to 'Update Max Error Count for Schedules', :controller => 'contracts', :action => 'error_show'
  end

  controller do
    #layout 'active_admin',  :only => [:new]
    include ApplicationHelper

    def error_show
      @contract = Contract.find_by_id(params["id"])
      pp @contract
      render "admin/contracts/update_error_contract"
    end

    def error_modification
      schedules = Schedule.joins(:project).joins(:contract).where(contract: {id: params["contract"]["id"]})
      ActiveRecord::Base.transaction do
        schedules.update_all(max_number_of_errors: params["contract"]["max_number_of_errors"])
        ScheduleHistory.mass_add_change(schedules, "max_number_of_errors", params["contract"]["max_number_of_errors"], current_active_admin_user)
      end
      redirect_to admin_contract_path(params["contract"]["id"]), :notice => "Max number of errors was updated."
    end


    before_action :only => [:index] do
      if params['commit'].blank?
        params['q'] = {:is_deleted_eq => '0'}
      end
    end

    def scoped_collection
      end_of_association_chain.with_mutes
    end

    def update
      @contract = Contract.where("id = ?", params[:id]).first
      public_attributes = Contract.get_public_attributes
      ActiveRecord::Base.transaction do
        public_attributes.each do |attr|
          if (!same?(params[:contract][attr], @contract[attr]))
            ContractHistory.add_change(@contract.id, attr, params[:contract][attr].to_s, current_active_admin_user)
            @contract[attr] = params[:contract][attr]
          end
        end
        @contract.tag_list = params["contract"]["tag_list"]
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
      @contract.customer_id = params["customer_id"]
      new!
    end

    def create
      public_attributes = Contract.get_public_attributes
      @contract = nil
      ActiveRecord::Base.transaction do
        @contract = Contract.new
        @contract.name = params[:contract]["name"]
        @contract.customer_id = params[:contract]["customer_id"]
        @contract.sla_enabled = params[:contract]["sla_enabled"]
        @contract.sla_type = params[:contract]["sla_type"]
        @contract.sla_value = params[:contract]["sla_value"]
        @contract.sla_percentage = params[:contract]["sla_percentage"]
        @contract.monitoring_enabled = params[:contract]["monitoring_enabled"]
        @contract.monitoring_treshhold = params[:contract]["monitoring_treshhold"]
        @contract.contract_type = params[:contract]["contract_type"]
        if @contract.save
          public_attributes.each do |attr|
            if (!same?(params[:contract][attr], @contract[attr]))
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
      redirect_to admin_contracts_path, :notice => "Contract was deleted!"
    end

    def autocomplete_tags
      @tags = ActsAsTaggableOn::Tag.where("name LIKE ?", "#{params[:q]}%").order(:name)
      respond_to do |format|
        format.json { render json: @tags, :only => [:id, :name] }
      end
    end
  end
end