source 'https://rubygems.org'

gem 'rails'
gem 'rails-api'
gem 'pg'

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.1.2'
# gem 'active_model_otp'
gem 'active_model_otp', '~> 1.1.0'
gem 'active_model_serializers', '~> 0.8.0'
gem 'postgres_ext-serializers', git: 'https://github.com/dockyard/postgres_ext-serializers.git'
# Gem does not released for this issue-fix. Once released remove git reference.
# "Hard-destroy of Parent record should destroy child records"
gem 'paranoia', github: 'radar/paranoia', ref: 'fe70628'

gem 'dotenv-rails', '0.11.1' # v1.0.2 of dotenv-rails doesn't preload ENV before Pusher gem loads
gem 'cancancan'
gem 'cloudinary'
gem 'factory_girl_rails' # used in rake db:seed in production
gem 'ffaker'
gem 'execjs'
gem 'jwt', '~> 0.1.13'
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
gem 'nestful'

group :development do
  unless ENV["CI"]
    gem 'spring'
    gem 'capistrano-rails'
    gem 'capistrano-bundler'
    gem 'capistrano-rvm'
    gem 'annotate'
    gem 'railroady'
    gem "spring-commands-rspec", group: :development
    gem 'guard-rspec', require: false
  end
end

group :development, :test do
  gem 'byebug', platform: 'mri' unless ENV["CI"] or ENV["RM_INFO"]
  gem 'rspec-rails'
end

group :test do
  gem 'vcr'
  gem 'webmock'
  gem 'shoulda-matchers', require: false
  gem "shoulda-callback-matchers"
  gem "codeclimate-test-reporter", require: nil if ENV["CI"]
end

group :production do
  gem 'airbrake'
  gem 'sucker_punch'
end
