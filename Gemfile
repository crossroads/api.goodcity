source 'https://rubygems.org'
ruby "2.5.1"

gem 'rails', '~> 5.0.0.0'
gem 'rails-api', '>= 0.4.1'
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
gem 'loofah', '>= 2.3.1'
gem 'cloudinary'
gem 'factory_bot_rails' , '>= 4.10.0' # used in rake db:seed in production
gem 'ffaker'
gem 'execjs'
# shivani - changed from jwt 0.1.13 to 1.2.0
gem 'jwt', '~> 1.5.0'
gem 'puma', '>= 4.3.1'
gem 'rack-cors', '>= 1.0.6'
gem 'rack-protection', '>= 2.0.3'
gem 'state_machine'
gem 'twilio-ruby', '~> 5.11.0'
gem 'warden', '>= 1.2.6'
gem 'rack-timeout'
gem 'newrelic_rpm'
gem 'traco'
gem 'rails-i18n', '>= 5.0.0'
gem 'http_accept_language'
gem 'oj'
gem 'redis'
gem 'redis-rails', '>= 5.0.2'
gem 'rollbar'
gem 'apipie-rails' , git: "https://github.com/Apipie/apipie-rails.git", branch: 'master'
gem "go_go_van_api", git: "git@github.com:crossroads/go_go_van_api.git", branch: 'master'
gem 'by_star', git: "https://github.com/radar/by_star.git"
gem 'nestful', git: "https://github.com/maccman/nestful.git"
gem "nokogiri", ">= 1.10.8"
gem 'sidekiq', '>= 4.2.10'
gem 'sidekiq-statistic', '>= 1.2.0'
gem 'sinatra', '>= 2.0.0', require: nil # for sidekiq reporting console
gem 'lograge', '>= 0.11.2'
gem 'paper_trail', '~> 4.0.0.beta'
# gem 'rubyXL', '~>3.3.8' # only enable when needed for writing xlsx file into yml
gem 'request_store'
gem 'easyzpl', git: 'https://github.com/crossroads/easyzpl.git'
gem 'active_record_union'
gem 'kaminari', '>= 0.16.3'
gem 'sidekiq-scheduler', '>= 2.1.2'
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
  gem 'rspec-rails', '>= 3.5.0'
  gem 'capistrano-rails'
  gem 'capistrano-bundler'
  gem 'capistrano-rvm'
  gem 'capistrano-rake', require: false
end

group :test do
  gem 'simplecov', require: false
  gem 'webmock'
  gem 'shoulda-matchers'
  gem "shoulda-callback-matchers"
  gem 'rspec_junit_formatter'
  gem 'timecop'
  gem 'cucumber-rails', '>= 1.8.0', require: false
  gem 'database_cleaner'
end
