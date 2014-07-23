source 'https://rubygems.org'

gem 'rails', '4.1.1'
gem 'rails-api'
gem 'pg'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.1.2'
gem 'active_model_otp'
gem 'active_model_serializers'
gem 'cancancan', '~> 1.8'
gem 'cloudinary'
gem 'factory_girl_rails' # used in rake db:seed in production
gem 'ffaker'
gem 'execjs'
gem 'jwt', '~> 0.1.13'
gem 'rack-cors'
gem 'rack-protection'
gem 'surus'
gem 'twilio-ruby'
gem 'warden'
gem 'puma'
gem 'rack-timeout'

group :development do
  gem 'spring'
  gem 'capistrano-rails'
  gem 'capistrano-bundler'
  gem 'capistrano-rvm'
  gem 'annotate'
  gem 'railroady'
end

group :development, :test do
  gem 'byebug', platform: 'mri'
  gem 'rspec-rails'
end

group :test do
  gem 'guard-rspec'
  gem 'shoulda-matchers'
end

group :production do
  gem 'airbrake'
  gem 'sucker_punch'
  gem 'connection_pool' # for threading with dalli
  gem 'dalli'
end
