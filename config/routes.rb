Rails.application.routes.draw do
  apipie
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".
  root :controller => 'static', :action => '/'

  namespace "api" do
    namespace "v1", defaults: { format: "json" } do
      resources :items
      post "auth/signup" => "authentication#signup"
      post "auth/verify" => "authentication#verify"
      post "auth/send_pin" => "authentication#send_pin"
      get "auth/current_user_profile" => "authentication#current_user_profile"

      get  "districts" => "districts#index"
      get  "districts/:id" => "districts#show"
      get  "item_types" => "item_types#index"
      get  "item_types/:id" => "item_types#show"
      get  "permissions" => "permissions#index"
      get  "permissions/:id" => "permissions#show"
      get  "images/generate_signature" => "images#generate_signature"
      get  "messages" => "messages#index"
      get  "messages/:id" => "messages#show"
      post "messages" => "messages#create"
      put  "messages/:id" => "messages#update"
      put  "messages/:id/mark_read" => "messages#mark_read"

      get  "offers" => "offers#index"
      get  "offers/:id" => "offers#show"
      post "offers" => "offers#create"
      put  "offers/:id" => "offers#update"
      delete "offers/:id" => "offers#destroy"
      put  "offers/:id/review" => "offers#review"

      get  "packages" => "packages#index"
      get  "packages/:id" => "packages#show"
      get  "rejection_reasons" => "rejection_reasons#index"
      get  "rejection_reasons/:id" => "rejection_reasons#show"
      get  "territories" => "territories#index"
      get  "territories/:id" => "territories#show"
      get  "donor_conditions" => "donor_conditions#index"
      get  "donor_conditions/:id" => "donor_conditions#show"
      get  "users" => "users#index"
      get  "users/:id" => "users#show"

      post "addresses" => "addresses#create"
      get  "addresses/:id" => "addresses#show"
      post "contacts" => "contacts#create"
      post "deliveries" => "deliveries#create"
      get  "deliveries/:id" => "deliveries#show"
      put  "deliveries/:id" => "deliveries#update"
      get  "schedules" => "schedules#availableTimeSlots"
      post "schedules" => "schedules#create"
    end
  end
end
