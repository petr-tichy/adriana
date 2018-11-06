ActiveAdmin.register AdminUser do
  role_changeable
  menu :priority => 7, :parent => 'Settings'
  permit_params :email, :password, :password_confirmation, :remember_me, :role
  filter :email
  filter :current_sign_in_at
  filter :sign_in_count
  filter :created_at

  index do
    selectable_column
    column :email
    column :role
    column :current_sign_in_at
    column :last_sign_in_at
    column :sign_in_count
    actions
  end

  form do |f|
    f.inputs "Admin Details" do
      f.input :email
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end
end
