# frozen_string_literal: true

# Optional opt-out from per-example transaction rollback (ActiveRecord::TestFixtures).
# Default remains config.use_transactional_fixtures in rails_helper.rb.
#
# Use when rollback is not enough (e.g. PostgreSQL sequences / identity after nextval)
# or when testing top-level transactions. You must still clean tables in before(:each)
# if other examples touch the same data — see spec/models/inventory_number_spec.rb.
#
#   RSpec.describe MyThing, :non_transactional do
#     before(:each) { truncate_or_delete_rows }
#     ...
#   end
#
#   it "commits for real", :non_transactional do
#     ...
#   end
#
RSpec.configure do |config|
  config.around(:each, :non_transactional) do |example|
    group = self.class
    unless group.respond_to?(:use_transactional_tests)
      example.run
      next
    end

    was = group.use_transactional_tests
    group.use_transactional_tests = false
    example.run
  ensure
    group.use_transactional_tests = was
  end
end
