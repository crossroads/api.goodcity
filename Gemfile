# frozen_string_literal: true

source 'https://rubygems.org'
ruby '2.6.1'

gem 'pg'
gem 'rails', '~> 6.1.3'
gem 'rake'

gem 'active_model_otp'
gem 'active_model_serializers', '~> 0.8.0'
gem 'active_record_union'
gem 'apipie-rails', git: "https://github.com/Apipie/apipie-rails.git", branch: 'master'
gem 'bootsnap', require: false
gem 'by_star', git: "https://github.com/radar/by_star.git"
gem 'cancancan'
gem 'cloudinary'
gem 'dotenv-rails', '0.11.1' # v1.0.2 of dotenv-rails doesn't preload ENV before Pusher gem loads
gem 'easyzpl', git: 'https://github.com/crossroads/easyzpl.git'
gem 'factory_bot_rails' # used in rake db:seed in production
gem 'fake_email_validator'
gem 'ffaker'
gem 'go_go_van_api', git: 'git@github.com:crossroads/go_go_van_api.git', branch: 'master'
gem 'guid'
gem 'http_accept_language'
gem 'jwt', '~> 2.2.2'
gem 'kaminari'
gem 'lograge'
gem 'loofah', '>= 2.3.1'
gem 'nestful', git: 'https://github.com/maccman/nestful.git'
gem 'newrelic_rpm'
gem 'nokogiri', '>= 1.10.8'
gem 'oj'
gem 'paper_trail'
gem 'paranoia'
gem 'puma', '>= 4.3.1'
gem 'rack-cors', require: 'rack/cors'
gem 'rack-protection'
gem 'rack-timeout', require: 'rack/timeout/base'
gem 'rails-i18n'
gem 'rake-progressbar'
gem 'redis'
gem 'redis-rails'
gem 'request_store'
gem 'rollbar'
gem 'rotp', '~> 3.3.1'
gem 'rubyXL'
gem 'sendgrid-ruby'
gem 'sidekiq', '~> 6.1.1'
gem 'sidekiq-scheduler'
gem 'sidekiq-statistic'
gem 'sinatra', require: nil # for sidekiq reporting console
gem 'slack-ruby-client'
gem 'state_machine'
gem 'traco'
gem 'twilio-ruby', '~> 5.11.0'
gem 'whenever', '~>  0.9.5', require: false
gem 'with_advisory_lock'
gem 'jsonapi-serializer'
gem 'jsonapi-serializer-formats'

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
  gem 'ruby-graphviz' # only enable when needed for workflow diagram generation
  gem 'spring'
  gem 'spring-commands-rspec', group: :development
end

group :development, :test do
  gem 'byebug'
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'capistrano-rake', require: false
  gem 'capistrano-rvm'
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
  gem 'simplecov', '~> 0.16.1', require: false
  gem 'timecop'
  gem 'webmock'
end
