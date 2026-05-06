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

  # Per-example DB transaction (ActiveRecord::TestFixtures) — rolls back after each
  # example so data does not leak between tests. Aliased as use_transactional_examples.
  #
  # Not rolled back: before(:suite) / after(:suite) (e.g. system user below). PostgreSQL
  # sequences are not rewound by rollback; specs that need TRUNCATE ... RESTART IDENTITY
  # set self.use_transactional_tests = false or use metadata :non_transactional — see
  # spec/support/transactional_test_isolation.rb and spec/models/inventory_number_spec.rb.
  config.use_transactional_fixtures = true

  config.infer_spec_type_from_file_location!

  config.include FactoryBot::Syntax::Methods

  # Apipie can record examples using "APIPIE_RECORD=examples rake"
  config.filter_run :show_in_doc => true if ENV['APIPIE_RECORD']

  FactoryBot.use_parent_strategy = false

  config.before(:suite) do
    Time.zone = 'Hong Kong'
    # Commits outside per-example transactions; visible to all examples.
    FactoryBot.create(:user, :system) unless User.system_user.present?
  end

  # Default app to be 'admin' in order to not use treat_user_as_donor
  config.include ApplicationHeaders
  config.before(:each, type: :controller) do
    set_admin_app_header
  end

  # Keep RequestStore clean between specs; reset ActiveJob test queues between examples
  config.before(:each) do
    RequestStore.clear!
    clear_enqueued_jobs
    clear_performed_jobs
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
