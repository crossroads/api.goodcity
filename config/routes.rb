Rails.application.routes.draw do
  apipie
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".
  root :controller => 'static', :action => '/'

  namespace "api" do
    namespace "v1", defaults: { format: "json" } do
      resources :items, except: [:index]
      post "auth/signup" => "authentication#signup"
      post "auth/verify" => "authentication#verify"
      post "auth/send_pin" => "authentication#send_pin"
      post "auth/register_device" => "authentication#register_device"
      get "auth/current_user_rooms" => "authentication#current_user_rooms"
      get "auth/current_user_profile" => "authentication#current_user_profile"

      get  "districts" => "districts#index"
      get  "districts/:id" => "districts#show"
      get  "item_types" => "item_types#index"
      get  "item_types/:id" => "item_types#show"
      post "item_types" => "item_types#create"
      get  "permissions" => "permissions#index"
      get  "permissions/:id" => "permissions#show"
      get  "images/generate_signature" => "images#generate_signature"
      post "images" => "images#create"
      put  "images/:id" => "images#update"
      delete "images/:id" => "images#destroy"
      get  "messages" => "messages#index"
      get  "messages/:id" => "messages#show"
      post "messages" => "messages#create"
      put  "messages/:id" => "messages#update"
      put  "messages/:id/mark_read" => "messages#mark_read"

      get  "offers/ggv_order_offer" => "offers#ggv_order_offer"
      get  "offers" => "offers#index"
      get  "offers/:id" => "offers#show"
      post "offers" => "offers#create"
      put  "offers/:id" => "offers#update"
      delete "offers/:id" => "offers#destroy"
      put  "offers/:id/review" => "offers#review"
      put  "offers/:id/complete_review" => "offers#complete_review"
      put  "offers/:id/close_offer" => "offers#close_offer"


      get  "packages" => "packages#index"
      get  "packages/:id" => "packages#show"
      post "packages" => "packages#create"
      put  "packages/:id" => "packages#update"
      delete "packages/:id" => "packages#destroy"

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
      delete "deliveries/:id" => "deliveries#destroy"

      get  "schedules" => "schedules#availableTimeSlots"
      post "schedules" => "schedules#create"

      post "gogovan_orders" => "gogovan_orders#confirm_order"
      post "gogovan_orders/calculate_price" => "gogovan_orders#calculate_price"

      get "available_dates" => "holidays#available_dates"
      get "timeslots" => "timeslots#index"
      get "gogovan_transports" => "gogovan_transports#index"
      get "crossroads_transports" => "crossroads_transports#index"
    end
  end
end
