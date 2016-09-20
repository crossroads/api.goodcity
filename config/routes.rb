Rails.application.routes.draw do
  apipie
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".
  root :controller => 'static', :action => '/'

  namespace "api" do
    namespace "v1", defaults: { format: "json" } do

      get "browse/fetch_packages", to: "browse#fetch_packages"

      post "auth/signup", to: "authentication#signup"
      post "auth/verify", to: "authentication#verify"
      post "auth/send_pin", to: "authentication#send_pin"
      post "auth/register_device", to: "authentication#register_device"
      get "auth/current_user_rooms", to: "authentication#current_user_rooms"
      get "auth/current_user_profile", to: "authentication#current_user_profile"
      get "braintree/generate_token", to: "braintree#generate_token"
      post "braintree/make_transaction", to: "braintree#make_transaction"

      resources :districts, only: [:index, :show]
      resources :package_types, only: [:index, :create]
      resources :permissions, only: [:index, :show]
      resources :boxes, only: [:create]
      resources :pallets, only: [:create]

      resources :images, only: [:create, :update, :destroy, :show] do
        collection do
          get :generate_signature
          put :delete_cloudinary_image
        end
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
          put :receive_offer
          put :mark_inactive
          put :merge_offer
        end
      end

      resources :items, except: [:index] do
        get :messages, on: :member
      end

      resources :packages, only: [:index, :show, :create, :update, :destroy] do
        get :print_inventory_label, on: :member
      end
      resources :rejection_reasons, only: [:index, :show]
      resources :cancellation_reasons, only: [:index, :show]
      resources :territories, only: [:index, :show]
      resources :donor_conditions, only: [:index, :show]
      resources :users, only: [:index, :show, :update]
      resources :addresses, only: [:create, :show]
      resources :contacts, only: [:create]
      resources :versions, only: [:index, :show]
      resources :holidays, only: [:index, :create, :destroy, :update]

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

      post "packages/print_barcode", to: "packages#print_barcode"

      resources :package_categories, only: [:index, :show]
      resources :locations, only: [:index, :create, :destroy]
      resources :stockit_organisations, only: [:create]
      resources :stockit_contacts, only: [:create]
      resources :stockit_local_orders, only: [:create]
      resources :orders, only: [:create, :show, :index]
      resources :stockit_activities, only: [:create]
      resources :countries, only: [:create]
      resources :inventory_numbers, only: [:create] do
        put :remove_number, on: :collection
      end

      # routes used in stock app
      get "designations", to: "orders#index"
      get "designations/:id", to: "orders#show"
      get "items", to: "packages#search_stockit_items"
      put "items/:id/designate_stockit_item", to: "packages#designate_stockit_item"
      put "items/:id/designate_stockit_item_set", to: "items#designate_stockit_item_set"
      put "items/:id/dispatch_stockit_item_set", to: "items#dispatch_stockit_item_set"
      put "items/:id/undesignate_stockit_item", to: "packages#undesignate_stockit_item"
      put "items/:id/dispatch_stockit_item", to: "packages#dispatch_stockit_item"
      put "items/:id/undispatch_stockit_item", to: "packages#undispatch_stockit_item"
      put "items/:id/move_stockit_item", to: "packages#move_stockit_item"
      put "items/:id/move_stockit_item_set", to: "items#move_stockit_item_set"
      put "items/:id/remove_from_set", to: "packages#remove_from_set"
      get "stockit_items/:id", to: "packages#stockit_item_details"
    end
  end
end
