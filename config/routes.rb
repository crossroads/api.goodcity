Rails.application.routes.draw do
  apipie
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".
  root :controller => 'static', :action => '/'

  namespace "api" do
    namespace "v1", defaults: { format: "json" } do

      get "browse/fetch_items", to: "browse#fetch_items"
      post "auth/signup", to: "authentication#signup"
      post "auth/verify", to: "authentication#verify"
      post "auth/send_pin", to: "authentication#send_pin"
      post "auth/register_device", to: "authentication#register_device"
      get "auth/current_user_rooms", to: "authentication#current_user_rooms"
      get "auth/current_user_profile", to: "authentication#current_user_profile"

      resources :districts, only: [:index, :show]
      resources :package_types, only: [:index]
      resources :permissions, only: [:index, :show]

      resources :images, only: [:create, :update, :destroy] do
        get :generate_signature, on: :collection
      end

      resources :messages, only: [:create, :update, :index, :show] do
        put :mark_read, on: :member
      end

      resources :offers, only: [:create, :update, :index, :show, :destroy] do
        member do
          get :messages
          put :review
          put :complete_review
          put :close_offer
        end
      end

      resources :items, except: [:index] do
        get :messages, on: :member
      end

      resources :packages, only: [:index, :show, :create, :update, :destroy]
      resources :rejection_reasons, only: [:index, :show]
      resources :cancellation_reasons, only: [:index, :show]
      resources :territories, only: [:index, :show]
      resources :donor_conditions, only: [:index, :show]
      resources :users, only: [:index, :show, :update]
      resources :addresses, only: [:create, :show]
      resources :contacts, only: [:create]

      post "confirm_delivery", to: "deliveries#confirm_delivery"
      resources :deliveries, only: [:create, :show, :update, :destroy]

      get  "schedules", to: "schedules#availableTimeSlots"
      post "schedules", to: "schedules#create"

      get  "gogovan_orders/driver_details", to: "gogovan_orders#driver_details"
      post "gogovan_orders", to: "gogovan_orders#confirm_order"
      post "gogovan_orders/calculate_price", to: "gogovan_orders#calculate_price"

      get "available_dates", to: "holidays#available_dates"
      get "timeslots", to: "timeslots#index"
      get "gogovan_transports", to: "gogovan_transports#index"
      get "crossroads_transports", to: "crossroads_transports#index"
      get "versions", to: "versions#index"

      post "twilio_inbound/voice", to: "twilio_inbound#voice"
      post "twilio_inbound/hold_donor", to: "twilio_inbound#hold_donor"
      post "twilio_inbound/accept_offer_id", to: "twilio_inbound#accept_offer_id"
      post "twilio_inbound/accept_callback", to: "twilio_inbound#accept_callback"
      post "twilio_inbound/send_voicemail", to: "twilio_inbound#send_voicemail"
      post "twilio_inbound/assignment", to: "twilio_inbound#assignment"
      get  "twilio_inbound/accept_call", to: "twilio_inbound#accept_call"
      get  "twilio_inbound/hold_music", to: "twilio_inbound#hold_music"
      post "twilio_inbound/call_complete", to: "twilio_inbound#call_complete"
      post "twilio_inbound/call_fallback", to: "twilio_inbound#call_fallback"

      post "twilio_outbound/connect_call", to: "twilio_outbound#connect_call"
      post "twilio_outbound/completed_call", to: "twilio_outbound#completed_call"
      post "twilio_outbound/call_status", to: "twilio_outbound#call_status"
      get  "twilio_outbound/generate_call_token", to:
        "twilio_outbound#generate_call_token"

      resources :package_categories, only: [:index, :show]
      resources :locations, only: [:index, :create]
    end
  end
end
