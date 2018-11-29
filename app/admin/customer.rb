ActiveAdmin.register Customer do
  menu :priority => 8, :parent => 'Resources'
  permit_params :name, :email, :contact_person

  filter :email
  filter :is_deleted, as: :check_boxes

  index row_class: ->(c) { 'row-highlight-deleted' if c.is_deleted } do
    selectable_column
    column :name do |c|
      link_to c.name, admin_customer_path(c)
    end
    column :email
    column :contact_person
    column :created_at
    column :updated_at
    column :actions do |customer|
      link_to 'New contract', :controller => 'contracts', :action => 'new', :customer_id => customer.id, :customer_name => customer.name
    end
  end

  show do
    panel('Customer') do
      attributes_table_for customer do
        row :name
        row :email
        row :contact_person
        row :updated_at
        row :created_at
        row :is_deleted
      end
    end
    panel('Contracts') do
      table_for Contract.where('customer_id = ?', params['id']) do
        column(:name) do |c|
          link_to c.name, admin_contract_path(c.id)
        end
        column(:updated_at)
        column(:created_at)
      end
    end
    panel('History') do
      table_for CustomerHistory.where('customer_id = ?', params['id']) do
        column(:key)
        column(:value)
        column(:updated_by) do |c|
          AdminUser.find_by_id(c.updated_by)&.email || '-'
        end
      end
    end
  end

  config.clear_action_items!

  action_item :edit, only: :show do
    link_to 'Edit Customer', edit_admin_customer_path(customer) if authorized? :edit, customer
  end

  action_item :destroy, only: :show do
    link_to customer.is_deleted ? 'Un-delete Customer' : 'Delete Customer', admin_customer_path(customer), :method => :delete if authorized? :destroy, customer
  end

  action_item :new_contract, :only => :show do
    link_to 'New contract', :controller => 'contracts', :action => 'new', :customer_id => customer.id, :customer_name => customer.name if authorized? :create, Contract
  end

  form do |f|
    f.inputs 'Customer' do
      f.input :name
      f.input :email
      f.input :contact_person
    end
    f.actions
  end


  controller do
    include ApplicationHelper

    before_filter :only => [:index] do
      if params['commit'].blank? && params['q'].blank?
        params['q'] = {:is_deleted_in => false}
      end
    end

    def update
      @customer = Customer.where('id = ?', params[:id]).first
      public_attributes = Customer.get_public_attributes

      ActiveRecord::Base.transaction do
        public_attributes.each do |attr|
          unless same?(params[:customer][attr], @customer[attr])
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
          redirect_to admin_customer_path(@customer.id), :notice => 'Customer was created!'
        else
          flash[:error] = 'Please review the errors below.'
          render action: 'new'
        end
      end
    end

    def destroy
      id = params[:id]
      customer = Customer.find_by_id(id)
      if customer.is_deleted
        ActiveRecord::Base.transaction do
          Customer.mark_deleted(id, current_active_admin_user, flag: false)
        end
        redirect_to admin_customers_path, :notice => 'Customer was un-deleted!'
      else
        ActiveRecord::Base.transaction do
          Customer.mark_deleted(id, current_active_admin_user, flag: true)
        end
        redirect_to admin_customers_path, :notice => 'Customer was deleted!'
      end
    end
  end
end