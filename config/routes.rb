Rails.application.routes.draw do
  apipie
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".
  root :controller => 'static', :action => '/'

  namespace "api" do
    namespace "v1", defaults: { format: "json" } do

      get "/browse/fetch_packages", to: "packages#index" #temporary redirect for old browse apps
      post "auth/signup", to: "authentication#signup"
      post "auth/verify", to: "authentication#verify"
      post "auth/send_pin", to: "authentication#send_pin"
      post "auth/register_device", to: "authentication#register_device"
      get "auth/current_user_rooms", to: "authentication#current_user_rooms"
      get "auth/current_user_profile", to: "authentication#current_user_profile"

      resources :districts, only: [:index, :show]
      resources :identity_types, only: [:index, :show]
      resources :package_types, only: [:index, :create]
      resources :permissions, only: [:index, :show]
      resources :roles, only: [:index, :show]
      resources :boxes, only: [:create]
      resources :pallets, only: [:create]
      resources :user_roles, only: [:show, :index, :create, :destroy]

      resources :stocktake_revisions, only: [:create, :update, :destroy]
      resources :stocktakes, only: [:show, :index, :destroy, :create] do
        put :commit, on: :member
        put :cancel, on: :member
      end

      resources :images, only: [:create, :update, :destroy, :show] do
        collection do
          get :generate_signature
          put :delete_cloudinary_image
        end
      end

      resources :messages, only: [:create, :update, :index, :show] do
        put :mark_read, on: :member
        put :mark_all_read, on: :collection
        get :notifications, on: :collection
      end

      resources :offers, only: [:create, :update, :index, :show, :destroy] do
        get 'summary', on: :collection
        collection do
          get :search
        end
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
      resources :offers_packages, only: [:destroy]

      resources :computers
      resources :computer_accessories
      resources :electricals
      resources :medicals
      resources :lookups, only: :index

      resources :items, except: [:index] do
        get :messages, on: :member
      end

      resources :package_sets, only: [:show, :update, :create, :destroy]
      resources :packages, only: [:index, :show, :create, :update, :destroy] do
        get :print_inventory_label, on: :member
        get :contained_packages, on: :member
        get :parent_containers, on: :member
        get :fetch_added_quantity, on: :member
        put :move, on: :member
        put :mark_missing, on: :member
        put :designate, on: :member
        put :add_remove_item, on: :member
        collection do
          get :package_valuation
        end
        member do
          get :versions
        end
      end

      resources :requested_packages, only: [:index, :create, :update, :destroy] do
        post :checkout, on: :collection
      end

      resources :rejection_reasons, only: [:index, :show]
      resources :cancellation_reasons, only: [:index, :show]
      resources :territories, only: [:index, :show]
      resources :goodcity_requests, only: [:index, :create, :update, :destroy]
      resources :goodcity_settings, only: [:index, :create, :update, :destroy]
      resources :donor_conditions, only: [:index, :show]
      resources :companies, only: [:create, :update, :show, :index]
      resources :users, only: [:index, :show, :update, :create] do
        member do
          get :orders_count
        end
      end
      resources :addresses, only: [:create, :show]
      resources :contacts, only: [:create]
      resources :versions, only: [:index, :show]
      resources :holidays, only: [:index, :create, :destroy, :update]
      resources :orders_packages
      resources :packages_locations, only: [:index, :show]
      resources :organisations_users, only: [:create, :index, :update, :show]
      resources :gc_organisations do
        get 'names', on: :collection
        member do
          get :orders
        end
      end
      resources :organisation_types

      get "recent_users", to: "users#recent_users"
      get "mentionable_users", to: "users#mentionable_users"

      get "appointment_slots/calendar", to: "appointment_slots#calendar"
      resources :appointment_slots, only: [:create, :destroy, :index, :update]
      resources :appointment_slot_presets, only: [:create, :destroy, :index, :update]

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
      get "booking_types", to: "booking_types#index"
      get "printers", to: "printers#index"
      get "process_checklists", to: "process_checklists#index"
      get "purposes", to: "purposes#index"
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
      resources :orders, only: [:create, :show, :index, :update, :destroy] do
        get 'summary', on: :collection
        member do
          put :transition
        end
      end
      resources :beneficiaries, only: [:create, :show, :index, :update, :destroy]
      resources :order_transports, only: [:create, :show, :index, :update]
      resources :stockit_activities, only: [:create]
      resources :countries, only: %i[create index]
      resources :inventory_numbers, only: [:create] do
        put :remove_number, on: :collection
      end
      resources :orders_process_checklists, only: [:index]
      resources :restrictions, only: [:index]
      resources :packages_inventories, only: [:index]
      resources :printers_users, only: [:create, :update]

      # routes used in stock app
      get "designations", to: "orders#index"
      get "designations/:id", to: "orders#show"
      get "items", to: "packages#search_stockit_items"
      put "items/:id/split_item", to: "packages#split_package"
      put "items/:id/move", to: "packages#move"
      put "items/:id/remove_from_set", to: "packages#remove_from_set"
      get "stockit_items/:id", to: "packages#stockit_item_details"
      put "orders_packages/:id/actions/:action_name", to: "orders_packages#exec_action"
      put "packages/:id/actions/:action_name", to: "packages#register_quantity_change"
    end
  end
end
