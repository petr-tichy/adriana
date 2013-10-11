ActiveAdmin.register Customer do

  #filter :project_pid
  #filter :sla_enabled, :as => :check_boxes, :collection => [true,false]
  #filter :sla_type, :as => :select, :collection => proc {Project.select("DISTINCT sla_type as name").where("sla_type != '' ")}


  index do
    column :name
    column :contact_email
    column :contact_person
    column :created_at
    column :updated_at
    column :actions do |customer|
      link_to "Synchronization", :controller => "jobs", :action => "new",:type => "synchronize_customer",:customer => customer.id
    end
    actions
  end

  form do |f|
    f.inputs "Customer" do
      f.input :name
      f.input :contact_email
      f.input :contact_person
      # etc
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
      customer = Customer.where("id = ?",params[:id]).first
      customer.is_deleted = true
      customer.save

      redirect_to admin_customers_path,:notice => "Customer was deleted!"
    end


  end





end