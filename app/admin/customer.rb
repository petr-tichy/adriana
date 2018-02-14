ActiveAdmin.register Customer do
  menu :priority => 8

  #filter :project_pid
  #filter :sla_enabled, :as => :check_boxes, :collection => [true,false]
  #filter :sla_type, :as => :select, :collection => proc {Project.select("DISTINCT sla_type as name").where("sla_type != '' ")}


  index do
    column :name
    column :email
    column :contact_person
    column :created_at
    column :updated_at
    column :actions do |customer|
      link_to "New contract", :controller => "contracts", :action => "new",:id => customer.id,:customer_name => customer.name
    end
    actions
  end


  show do
    panel ("Customer") do
      attributes_table_for customer do
        row :name
        row :email
        row :contact_person
        row :updated_at
        row :created_at
        row :is_deleted
      end
    end
    panel ("") do
      table_for Contract.where("customer_id = ?",params["id"]) do
        column(:name)
        column(:updated_at)
        column(:created_at)
      end
    end
  end

  action_item :only => :show do
    link_to "New contract", :controller => "contracts", :action => "new",:id => customer.id,:customer_name => customer.name
  end

  form do |f|
    f.inputs "Customer" do
      f.input :name
    end
    f.actions
  end


  controller do
    include ApplicationHelper

    before_filter :only => [:index] do
      if params['commit'].blank?
        params['q'] = {:is_deleted_eq => '0'}
      end
    end

    def update
      customer = Customer.where("id = ?",params[:id]).first
      public_attributes = Customer.get_public_attributes

      ActiveRecord::Base.transaction do
        public_attributes.each do |attr|
          if (!same?(params[:customer][attr],customer[attr]))
            CustomerHistory.add_change(customer.id,attr,params[:customer][attr].to_s,current_active_admin_user)
            customer[attr] = params[:customer][attr]
          end
        end
        customer.save
      end
      redirect_to admin_customer_path(params[:id])
    end


    def create
      public_attributes = Customer.get_public_attributes
      customer = nil
      ActiveRecord::Base.transaction do
        customer = Customer.new()
        public_attributes.each do |attr|
          customer[attr] =  params[:customer][attr]
        end
        customer.save
        public_attributes.each do |attr|
          CustomerHistory.add_change(customer.id,attr,params[:customer][attr].to_s,current_active_admin_user)
        end
      end
      redirect_to admin_customer_path(customer.id)
    end

    def destroy
        ActiveRecord::Base.transaction do
          Customer.mark_deleted(params[:id],current_active_admin_user)
        end
      redirect_to admin_customers_path,:notice => "Customer was deleted!"
    end


  end





end