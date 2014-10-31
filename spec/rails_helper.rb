# This file is copied to spec/ when you run 'rails generate rspec:install'
if ENV["CI"]
  require "codeclimate-test-reporter"
  CodeClimate::TestReporter.start
end
ENV["RAILS_ENV"] ||= 'test'
require 'support/env' # Must load our dummy env vars before rails
require 'spec_helper'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'

require 'ffaker'
require 'shoulda/matchers'
require 'webmock/rspec'
require 'vcr'

WebMock.disable_net_connect!

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

  Warden.test_mode!

  config.after(:each) do
    Warden.test_reset!
  end

  config.use_transactional_fixtures = true

  config.infer_spec_type_from_file_location!

  config.include FactoryGirl::Syntax::Methods

  # Apipie can record examples using "APIPIE_RECORD=examples rake"
  config.filter_run :show_in_doc => true if ENV['APIPIE_RECORD']

  config.before(:each) do
    User.current = FactoryGirl.create :user
  end

end
