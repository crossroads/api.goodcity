source 'https://rubygems.org'

gem 'rails', '4.1.1'
gem 'rails-api'
gem 'pg'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.1.2'

gem 'cancancan', '~> 1.8'
gem 'factory_girl_rails' # used in rake db:seed in production
gem 'ffaker'
gem 'active_model_serializers'
gem 'execjs'
gem 'cloudinary'
gem 'surus'
gem 'rack-cors'

group :development do
  gem 'spring'
  gem 'capistrano-rails'
  gem 'capistrano-bundler'
  gem 'capistrano-rvm'
  gem 'annotate'
  gem 'thin'
  gem 'railroady'
end

group :development, :test do
  gem 'debugger'
  gem 'rspec-rails'
end

group :test do
  gem 'guard-rspec'
  gem 'shoulda-matchers'
end

group :production do
  gem 'airbrake'
  gem 'sucker_punch'
end
