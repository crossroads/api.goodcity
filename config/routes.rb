Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  namespace "api" do
    namespace "v1", defaults: { format: "json" } do
      get "offers" => "offers#index"
      get "offers/:id" => "offers#show"
      put "offers/:id" => "offers#update"
      delete "offers/:id" => "offers#destroy"

      get "items" => "items#index"
      get "items/:id" => "items#show"
      get "item_types" => "item_types#index"
      post "items" => "items#create"
      get "item_types/:id" => "item_types#show"
      get "messages" => "messages#index"
      get "messages/:id" => "messages#show"
      get "packages" => "packages#index"
      get "packages/:id" => "packages#show"
      get "rejection_reasons" => "rejection_reasons#index"
      get "rejection_reasons/:id" => "rejection_reasons#show"
      get "users" => "users#index"
      get "users/:id" => "users#show"
      get "signup" => "users#new"
      get "login" => "sessions#new"
      get "logout" => "sessions#destroy"
      post "sessions" => "sessions#create"
    end
  end

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
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

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
