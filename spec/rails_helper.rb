# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
require "simplecov"
SimpleCov.start
ENV["RAILS_ENV"] ||= 'test'
require 'support/env' # Must load our dummy env vars before rails
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

require 'ffaker'
require 'webmock/rspec'
require 'paper_trail/frameworks/rspec'

WebMock.disable_net_connect!(:allow => "codeclimate.com")

# When running tests using bin/rspec (Spring), the Rails env is preloaded and stored.
# This means any secrets.yml variables that use ENV data will collect the development
# env INSTEAD of support/env file that is loaded above. To fix this, we clear the Rails
# secrets cache and force it to reload here every time that rspec or bin/rspec is run.
Rails.application.instance_variable_set('@secrets', nil)

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.

Dir[Rails.root.join('spec/support/*.rb')].each { |f| require f }
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|

  config.include Warden::Test::Helpers
  config.include Warden::Test::ControllerHelpers, type: :controller
  config.include ControllerMacros, type: :controller
  config.include ActiveJob::TestHelper

  Warden.test_mode!

  config.after(:each) do
    Warden.test_reset!
  end

  config.use_transactional_fixtures = true

  config.infer_spec_type_from_file_location!

  config.include FactoryBot::Syntax::Methods

  # Apipie can record examples using "APIPIE_RECORD=examples rake"
  config.filter_run :show_in_doc => true if ENV['APIPIE_RECORD']

  FactoryBot.create :user, :system

  # Default app to be 'admin' in order to not use treat_user_as_donor
  config.include ApplicationHeaders
  config.before(:each, type: :controller) do
    set_admin_app_header
  end

  # Keep RequestStore clean between specs
  config.before(:each) do
    RequestStore.clear!
  end

  config.before(:suite) do
    Time.zone = 'Hong Kong'
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
