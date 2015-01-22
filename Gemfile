source 'https://rubygems.org'

gem 'rails', '~> 4.2.0'
# gem 'activejob_backport' # remove this gem when Rails is upgraded to 4.2
gem 'rails-api'
gem 'pg'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.1.2'
# gem 'active_model_otp'
gem 'active_model_otp', '~> 1.1.0'
gem 'active_model_serializers', '~> 0.8.0'
gem 'postgres_ext', '~> 2.4.0.beta.1'
gem 'postgres_ext-serializers', git: 'https://github.com/crossroads/postgres_ext-serializers.git'
# Gem does not released for this issue-fix. Once released remove git reference.
# "Hard-destroy of Parent record should destroy child records"
gem 'paranoia', '~> 2.0.4'
# , github: 'radar/paranoia', ref: 'fe70628'
# Shivani - Should try config_for to load the .env
gem 'dotenv-rails', '0.11.1' # v1.0.2 of dotenv-rails doesn't preload ENV before Pusher gem loads

gem 'cancancan'
gem 'cloudinary'
gem 'factory_girl_rails' # used in rake db:seed in production
gem 'ffaker'
gem 'execjs'
# shivani - changed from jwt 0.1.13 to 1.2.0
gem 'jwt', '~> 1.2.0'
gem 'rack-cors'
gem 'rack-protection'
gem 'state_machine'
gem 'twilio-ruby'
gem 'warden'
gem 'puma' unless ENV["CI"]
gem 'rack-timeout'
gem 'newrelic_rpm' unless ENV["CI"]
gem 'traco'
gem 'rails-i18n'
gem 'http_accept_language'
gem 'oj', '2.10.2' # 2.10.3 causes a 'too deeply nested' error
gem 'oj_mimic_json'
gem 'redis'
gem 'redis-rails'
gem 'pusher'
gem 'apipie-rails'
gem "go_go_van_api", git: "git@github.com:crossroads/go_go_van_api.git", branch: 'master'
gem 'by_star', git: "git://github.com/radar/by_star"
gem 'nestful', git: "https://github.com/maccman/nestful.git"
gem 'nokogiri'
gem 'sidekiq'
gem 'sinatra', :require => nil # for sidekiq reporting console
gem 'airbrake'

group :development do
  unless ENV["CI"]
    gem 'spring'
    gem 'capistrano-rails'
    gem 'capistrano-bundler'
    gem 'capistrano-rvm'
    gem 'capistrano-sidekiq'
    gem 'annotate'
    gem 'railroady'
    gem "spring-commands-rspec", group: :development
    gem 'guard-rspec', require: false
    gem 'foreman', require: false
  end
end

group :development, :test do
  gem 'byebug', platform: 'mri' unless ENV["CI"] or ENV["RM_INFO"]
  gem 'rspec-rails'
end

group :test do
  gem 'webmock'
  gem 'shoulda-matchers', require: false
  gem "shoulda-callback-matchers"
  gem "codeclimate-test-reporter", require: nil if ENV["CI"]
end
