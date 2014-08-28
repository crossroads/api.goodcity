Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".
  root :controller => 'static', :action => '/'

  namespace "api" do
    namespace "v1", defaults: { format: "json" } do
      resources :items
      get  "auth/check_mobile" => "authentication#is_unique_mobile_number"
      get  "auth/verify_mobile" => "authentication#resend"
      post "auth/signup" => "authentication#signup"
      post "auth/verify" => "authentication#verify"
      get  "auth/resend" =>  "authentication#resend"
      get  "districts" => "districts#index"
      get  "districts/:id" => "districts#show"
      get  "item_types" => "item_types#index"
      get  "item_types/:id" => "item_types#show"
      get  "images/generate_signature" => "images#generate_cloudinary_signature"
      get  "messages" => "messages#index"
      get  "messages/:id" => "messages#show"
      get  "offers" => "offers#index"
      get  "offers/:id" => "offers#show"
      post "offers" => "offers#create"
      put  "offers/:id" => "offers#update"
      delete "offers/:id" => "offers#destroy"
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
      post "contacts" => "contacts#create"
    end
  end
end
