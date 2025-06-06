# frozen_string_literal: true

source 'https://rubygems.org'
ruby '2.7.3'

gem 'pg'
gem 'rails', '~> 6.1.4'
gem 'rake'

gem 'active_model_otp'
gem 'active_model_serializers', '~> 0.8.0'
gem 'active_record_union'
gem 'apipie-rails', git: "https://github.com/Apipie/apipie-rails.git", ref: "a55d836"
gem 'bootsnap', require: false
gem 'by_star'
gem 'cancancan'
gem 'cloudinary'
gem 'dotenv-rails'
gem 'easyzpl', git: 'https://github.com/crossroads/easyzpl.git'
gem 'factory_bot_rails' # used in rake db:seed in production
gem 'fake_email_validator'
gem 'ffaker'
gem 'go_go_van_api', git: 'git@github.com:crossroads/go_go_van_api.git', branch: 'master'
gem 'guid'
gem 'http_accept_language'
gem 'jwt'
gem 'kaminari'
gem 'lograge'
gem 'loofah'
gem 'nestful'
gem 'newrelic_rpm'
gem 'nokogiri'
gem 'oj'
gem 'paper_trail'
gem 'paranoia'
gem 'puma'
gem 'rack-cors', require: 'rack/cors'
gem 'rack-protection'
gem 'rack-timeout', require: 'rack/timeout/base'
gem 'rails-i18n'
gem 'rake-progressbar'
gem 'redis' # Used for Rails cache_store
gem 'request_store'
gem 'sentry-rails'
gem 'sentry-sidekiq'
gem 'rotp'
gem 'rubyXL'
gem 'sidekiq', '<8'
gem 'sidekiq-scheduler'
gem 'state_machine'
gem 'traco'
gem 'twilio-ruby'
gem 'whenever', require: false
gem 'with_advisory_lock'
gem 'jsonapi-serializer'
gem 'jsonapi-serializer-formats'
gem 'azure-storage-blob'

group :development, :staging do
  gem 'grape-swagger-rails'
end

group :development do
  gem 'annotate'
  gem 'bullet'
  gem 'foreman', require: false
  gem 'guard-rspec', require: false
  gem 'railroady'
  gem 'rb-readline'
  gem 'ruby-graphviz'
  gem 'spring'
  gem 'spring-commands-rspec', group: :development
  gem 'capistrano-rails'
  gem 'capistrano-bundler'
  gem 'capistrano-rake', require: false
  gem 'capistrano-rvm'
  gem 'ed25519'      # required for capistrano to use ssh with ed25519 keys
  gem 'bcrypt_pbkdf' # required for capistrano to use ssh with ed25519 keys
end

group :development, :test do
  gem 'byebug'
  gem 'rspec-rails'
end

group :test do
  gem 'cucumber-rails', require: false
  gem 'database_cleaner'
  gem 'email_spec'
  gem 'rails-controller-testing'
  gem 'rspec_junit_formatter'
  gem 'shoulda-callback-matchers'
  gem 'shoulda-matchers'
  gem 'simplecov', require: false
  gem 'timecop'
  gem 'webmock'
end
