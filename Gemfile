# frozen_string_literal: true

source 'https://rubygems.org'
ruby '2.5.1'

gem 'pg'
gem 'rails', '~> 5.0.7.1'
gem 'rake'

gem 'active_model_otp'
gem 'rotp', '~> 3.3.1'
gem 'active_model_serializers', '~> 0.8.0'
# TODO:  Make postgres_ext and postgres_ext_serializer compatible with rails 5 / Find other alternatives
# gem 'postgres_ext'
# gem 'postgres_ext-serializers', git: 'https://github.com/crossroads/postgres_ext-serializers.git', ref: '530a6f7426bff9bd69b3f2773cced146ba89e65c'
# Gem does not released for this issue-fix. Once released remove git reference.
# "Hard-destroy of Parent record should destroy child records"
gem 'paranoia'
# , github: 'radar/paranoia', ref: 'fe70628'
# Shivani - Should try config_for to load the .env
gem 'dotenv-rails', '0.11.1' # v1.0.2 of dotenv-rails doesn't preload ENV before Pusher gem loads

gem 'cancancan'
gem 'loofah', '>= 2.3.1'
gem 'cloudinary'
gem 'factory_bot_rails' # used in rake db:seed in production
gem 'ffaker'
# shivani - changed from jwt 0.1.13 to 1.2.0
gem 'jwt', '~> 1.5.0'
gem 'puma', '>= 4.3.1'
gem 'rack-cors'
gem 'rack-protection'
gem 'state_machine'
gem 'twilio-ruby', '~> 5.11.0'
gem 'warden'
gem 'rack-timeout', require: 'rack/timeout/base'
gem 'newrelic_rpm'
gem 'traco'
gem 'rails-i18n'
gem 'http_accept_language'
gem 'oj'
gem 'redis'
gem 'redis-rails'
gem 'rollbar'
gem 'apipie-rails' , git: "https://github.com/Apipie/apipie-rails.git", branch: 'master'
gem "go_go_van_api", git: "git@github.com:crossroads/go_go_van_api.git", branch: 'master'
gem 'by_star', git: "https://github.com/radar/by_star.git"
gem 'nestful', git: "https://github.com/maccman/nestful.git"
gem "nokogiri", ">= 1.10.8"
gem 'sidekiq'
gem 'sidekiq-statistic'
gem 'sinatra', require: nil # for sidekiq reporting console
gem 'lograge'
gem 'paper_trail'
# gem 'rubyXL', '~>3.3.8' # only enable when needed for writing xlsx file into yml
gem 'request_store'
gem 'easyzpl', git: 'https://github.com/crossroads/easyzpl.git'
gem 'active_record_union'
gem 'kaminari'
gem 'sidekiq-scheduler'
gem 'rake-progressbar'
gem 'slack-ruby-client'
gem 'whenever', '~>  0.9.5', require: false
gem 'sendgrid-ruby'
gem 'fake_email_validator'
gem 'with_advisory_lock'

group :development do
  gem 'spring'
  gem 'annotate'
  gem 'rb-readline'
  gem 'bullet'
  gem 'railroady'
  gem "spring-commands-rspec", group: :development
  gem 'guard-rspec', require: false
  gem 'foreman', require: false
  gem 'ruby-graphviz' # only enable when needed for workflow diagram generation
end

group :development, :test do
  gem 'byebug'
  gem 'rspec-rails'
  gem 'capistrano-rails'
  gem 'capistrano-bundler'
  gem 'capistrano-rvm'
  gem 'capistrano-rake', require: false
end

group :test do
  gem 'cucumber-rails', require: false
  gem 'database_cleaner'
  gem 'rails-controller-testing'
  gem 'rspec_junit_formatter'
  gem 'shoulda-callback-matchers'
  gem 'shoulda-matchers'
  gem 'simplecov', '~> 0.16.1', require: false
  gem 'timecop'
  gem 'webmock'
end
