ActiveAdmin.register Customer do
  menu :priority => 8
  permit_params :name, :email, :contact_person

  filter :project_pid
  filter :email
  filter :is_deleted, :as => :select, :collection => [['Yes', true], ['No', false]]

  index do
    column :name
    column :email
    column :contact_person
    column :created_at
    column :updated_at
    column :actions do |customer|
      link_to "New contract", :controller => "contracts", :action => "new", :customer_id => customer.id, :customer_name => customer.name
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
    panel ("Contracts") do
      table_for Contract.where("customer_id = ?", params["id"]) do
        column(:name)
        column(:updated_at)
        column(:created_at)
      end
    end
  end

  action_item :new_contract, :only => :show do
    link_to "New contract", :controller => "contracts", :action => "new", :customer_id => customer.id, :customer_name => customer.name
  end

  form do |f|
    f.inputs "Customer" do
      f.input :name
      f.input :email
      f.input :contact_person
    end
    f.actions
  end


  controller do
    include ApplicationHelper

    before_action :only => [:index] do
      if params['commit'].blank?
        params['q'] = {:is_deleted_eq => '0'}
      end
    end

    def update
      @customer = Customer.where("id = ?", params[:id]).first
      public_attributes = Customer.get_public_attributes

      ActiveRecord::Base.transaction do
        public_attributes.each do |attr|
          if (!same?(params[:customer][attr], @customer[attr]))
            CustomerHistory.add_change(@customer.id, attr, params[:customer][attr].to_s, current_active_admin_user)
            @customer[attr] = params[:customer][attr]
          end
        end
        if @customer.save
          redirect_to admin_customer_path(params[:id]), :notice => 'Customer was successfully updated.'
        else
          flash[:error] = 'Please review the errors below.'
          render action: 'edit'
        end
      end
    end

    def new
      @customer = Customer.new
      new!
    end

    def create
      public_attributes = Customer.get_public_attributes
      @customer = nil
      ActiveRecord::Base.transaction do
        @customer = Customer.new
        public_attributes.each do |attr|
          @customer[attr] = params[:customer][attr]
        end
        if @customer.save
          public_attributes.each do |attr|
            CustomerHistory.add_change(@customer.id, attr, params[:customer][attr].to_s, current_active_admin_user)
          end
          redirect_to admin_customer_path(@customer.id), :notice => 'Customer was created!'
        else
          flash[:error] = 'Please review the errors below.'
          render action: 'new'
        end
      end
    end

    def destroy
      ActiveRecord::Base.transaction do
        Customer.mark_deleted(params[:id], current_active_admin_user)
      end
      redirect_to admin_customers_path, :notice => "Customer was deleted!"
    end
  end
end