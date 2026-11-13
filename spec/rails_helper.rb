# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
require "simplecov"
SimpleCov.start
ENV["RAILS_ENV"] ||= 'test'
require 'support/env' # Must load our dummy env vars before rails
require File.expand_path('../config/environment', __dir__)
require 'rspec/rails'

require 'ffaker'
require 'webmock/rspec'
require 'paper_trail/frameworks/rspec'

require_relative "support/controller_macros"

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
  Kernel.srand 852

  config.include ControllerMacros, type: :controller
  config.include MigrationHelpers, type: :migration
  config.include ActiveJob::TestHelper
  config.include LocaleSwitcher
  config.include Touch
  config.include InventoryInitializer

  config.use_transactional_fixtures = true

  # Reference data is preloaded from spec/fixtures (see doc/spec-fixtures-plan.md).
  # Fixtures are inserted once per process, outside the per-example transaction.
  config.fixture_path = Rails.root.join('spec/fixtures').to_s
  config.global_fixtures = :all

  config.infer_spec_type_from_file_location!

  config.include FactoryBot::Syntax::Methods

  # Apipie can record examples using "APIPIE_RECORD=examples rake"
  config.filter_run :show_in_doc => true if ENV['APIPIE_RECORD']

  FactoryBot.use_parent_strategy = false

  # Create system_user
  config.before(:suite) do
    # Load fixtures first: the first example's fixture load deletes every row in a
    # fixtured table, which would orphan anything created here that references one.
    fixture_names = Dir[File.join(config.fixture_path, '**/*.yml')].map do |f|
      f.delete_prefix("#{config.fixture_path}/").delete_suffix('.yml')
    end
    ActiveRecord::FixtureSet.create_fixtures(config.fixture_path, fixture_names)
    FactoryBot.create(:user, :system)
  end

  # Clean up system_user at end of specs
  config.after(:suite) do
    User.system.destroy_all
  end

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
