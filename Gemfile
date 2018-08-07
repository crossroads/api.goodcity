source 'https://rubygems.org'
ruby "2.5.1"

gem 'rails', '~> 4.2.0'
gem 'rails-api'
gem 'pg'
gem 'rake'

gem 'active_model_otp', '~> 1.1.0'
gem 'active_model_serializers', '~> 0.8.0'
gem 'postgres_ext', '~> 2.4.0.beta.1'
gem 'postgres_ext-serializers', git: 'https://github.com/DockYard/postgres_ext-serializers.git', ref: '0c2d483806becd1ef7f8c9336286158cfdda1cc3'
# Gem does not released for this issue-fix. Once released remove git reference.
# "Hard-destroy of Parent record should destroy child records"
gem 'paranoia', '~> 2.1.0'
# , github: 'radar/paranoia', ref: 'fe70628'
# Shivani - Should try config_for to load the .env
gem 'dotenv-rails', '0.11.1' # v1.0.2 of dotenv-rails doesn't preload ENV before Pusher gem loads

gem 'cancancan'
gem 'loofah'
gem 'cloudinary'
gem 'factory_bot_rails' # used in rake db:seed in production
gem 'ffaker'
gem 'execjs'
# shivani - changed from jwt 0.1.13 to 1.2.0
gem 'jwt', '~> 1.2.0'
gem 'rack-cors'
gem 'rack-protection'
gem 'state_machine'
gem 'twilio-ruby'
gem 'warden'
gem 'puma'
gem 'rack-timeout'
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
gem 'nokogiri'
gem 'sidekiq'
gem 'sidekiq-statistic'
gem 'sinatra', require: nil # for sidekiq reporting console
gem 'lograge'
gem 'paper_trail', '~> 4.0.0.beta'
# gem 'rubyXL', '~>3.3.8' # only enable when needed for writing xlsx file into yml
gem 'request_store'
gem 'easyzpl', git: 'https://github.com/crossroads/easyzpl.git'
gem 'braintree'
gem 'active_record_union'
gem 'kaminari'
gem 'sidekiq-scheduler'
gem 'rake-progressbar'
gem 'slack-ruby-client'
gem 'whenever', '~>  0.9.5', require: false

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
  gem 'capistrano-sidekiq'
  gem 'capistrano-rake', require: false
end

group :test do
  gem 'simplecov', require: false
  gem 'webmock'
  gem 'shoulda-matchers'
  gem "shoulda-callback-matchers"
  gem 'rspec_junit_formatter'
  gem 'timecop'
end
