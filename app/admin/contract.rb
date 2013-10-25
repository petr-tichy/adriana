ActiveAdmin.register Contract do

  #filter :project_pid
  #filter :sla_enabled, :as => :check_boxes, :collection => [true,false]
  #filter :sla_type, :as => :select, :collection => proc {Project.select("DISTINCT sla_type as name").where("sla_type != '' ")}


  index do
    column :name
    column :created_at
    column :updated_at
    column :actions do |contract|
      link_to "Synchronization", :controller => "jobs", :action => "new",:type => "synchronize_contract",:contract => contract.id
    end
    actions
  end


  form do |f|
    f.inputs "Contract" do
      f.input :name
      # etc
    end
    f.actions
  end


  show do
    panel ("Contract") do
      attributes_table_for contract do
        row :name
        row :customer do |contract|
          customer = Customer.find(contract.customer_id)
          link_to customer.name,:controller => "customers",:action => "show",:id => customer.id
        end
        row :updated_at
        row :created_at
        row :is_deleted

      end
    end
  end


  controller do
    layout 'active_admin',  :only => [:new]
    include ApplicationHelper

    before_filter :only => [:index] do
      if params['commit'].blank?
        params['q'] = {:is_deleted_eq => '0'}
      end
    end

    def update
      contract = Contract.where("id = ?",params[:id]).first
      public_attributes = Contract.get_public_attributes

      ActiveRecord::Base.transaction do
        public_attributes.each do |attr|
          if (!same?(params[:contract][attr],contract[attr]))
            ContractHistory.add_change(contract.id,attr,params[:contract][attr].to_s,current_active_admin_user)
            contract[attr] = params[:contract][attr]
          end
        end
        contract.save
      end

      redirect_to admin_contract_path(params[:id])
    end


    def new
      render  "new_contract"
    end


    def create
      public_attributes = Contract.get_public_attributes
      contract = nil
      ActiveRecord::Base.transaction do
          contract = Contract.new()
          contract.name = params[:contracts]["name"]
          contract.customer_id = params[:contracts]["customer_id"]
          contract.save
          ContractHistory.add_change(contract.id,"name",params[:contracts]["name"],current_active_admin_user)
      end

      redirect_to admin_contract_path(contract.id),:notice => "Contract was created!"
    end

    def destroy
      ActiveRecord::Base.transaction do
        Contract.mark_deleted(params[:id],current_active_admin_user)
      end
      redirect_to admin_contracts_path,:notice => "Contract was deleted!"
    end


  end





end