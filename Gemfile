source 'https://rubygems.org'

gem 'rails', '4.1.1'
gem 'rails-api'
gem 'pg'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.1.2'
# gem 'active_model_otp'
gem 'active_model_otp', git: 'git@github.com:shivanibhanwal/active_model_otp'
gem 'active_model_serializers', '~> 0.8.0'

# Gem does not released for this issue-fix. Once released remove git reference.
# "Hard-destory of Parent record should destroy child records"
gem 'paranoia', git: 'https://github.com/radar/paranoia.git', ref: 'fe70628'

gem 'cancancan', '~> 1.8'
gem 'cloudinary'
gem 'factory_girl_rails' # used in rake db:seed in production
gem 'ffaker'
gem 'execjs'
gem 'jwt', '~> 0.1.13'
gem 'rack-cors'
gem 'rack-protection'
gem 'state_machine', '~> 1.2.0'
gem 'twilio-ruby'
gem 'warden'
gem 'puma'
gem 'rack-timeout'
gem 'newrelic_rpm'
gem 'traco'
gem 'rails-i18n', '~> 4'
gem 'http_accept_language', '~> 2.0.1'
gem 'dotenv-rails'
gem 'oj'
gem 'oj_mimic_json'
gem 'redis'
gem 'redis-rails'
gem 'pusher'

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
  gem 'simplecov', require: false
  gem 'shoulda-matchers'
  gem 'vcr'
  gem 'webmock'
end

group :production do
  gem 'airbrake'
  gem 'sucker_punch'
end
