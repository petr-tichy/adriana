ActiveAdminTest::Application.routes.draw do
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
  match '/api', to: 'api#index', via: :get
  match '/admin/autocomplete_tags', to: 'admin/contracts#autocomplete_tags', as: 'autocomplete_tags', via: :get

  resources :notification
  match '/feed' => 'notification#feed', as: :feed, defaults: { format: 'atom' }, via: :get


  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
