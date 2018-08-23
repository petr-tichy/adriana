Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root :to => 'admin/dashboard#index'

  devise_for :admin_users, ActiveAdmin::Devise.config
  begin
    ActiveAdmin.routes(self)
  rescue Exception => e
    # Throws errors that stop migrations execution
    # https://github.com/activeadmin/activeadmin/issues/783
    puts e
  end

  #TODO modify to the new rails way

  match '/admin/jobs/create_contract_sychnronization', to: 'admin/jobs#create', via: :post
  match '/admin/jobs/update_contract_sychnronization', to: 'admin/jobs#update', via: :put
  match '/admin/jobs/create_direct_sychnronization', to: 'admin/jobs#create', via: :post
  match '/admin/jobs/update_direct_sychnronization', to: 'admin/jobs#update', via: :put

  match '/admin/contracts/create', to: 'admin/contracts#create', via: :post
  match '/admin/contracts/error_show/:id', to: 'admin/contracts#error_show', via: :get
  match '/admin/contract/error_modification', to: 'admin/contracts#error_modification', via: :patch
  match '/admin/contracts/error_modification/:id', to: 'admin/contracts#error_modification', via: :put
  match '/admin/attask_print/create_job', to: 'admin/attask_print#create', via: :post
  match '/api', to: 'api#index', via: :get
  match '/admin/autocomplete_tags', to: 'admin/contracts#autocomplete_tags', as: 'autocomplete_tags', via: :get

  resources :notification
  match '/feed' => 'notification#feed', as: :feed, defaults: { format: 'atom' }, via: :get
end
