# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment',  __FILE__)
run Rails.application

require 'sidekiq/web'
map '/sidekiq' do
  use Rack::Auth::Basic, "Protected Area" do |username, password|
    username.present? && password.present? && username == ENV['SIDEKIQ_USERNAME'] && password == ENV['SIDEKIQ_PASSWORD']
  end
  
  use Rack::Session::Cookie, secret: Rails.application.secrets.secret_key_base, same_site: true, max_age: 86400
  run Sidekiq::Web
end
