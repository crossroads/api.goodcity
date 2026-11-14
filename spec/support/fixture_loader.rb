# frozen_string_literal: true

# Loads every spec/fixtures/*.yml. Shared by rspec (spec/rails_helper.rb) and cucumber
# (features/support/fixtures.rb), because the factories both use look up fixture rows
# (districts, locations, the bystander user) and fail without them.
#
# Rows are inserted and committed outside any test transaction, so they persist
# between examples, scenarios and runs. Each load first deletes every row in the
# fixtured tables, so call it before creating anything that references them.
module FixtureLoader
  PATH = File.expand_path('../fixtures', __dir__)

  def self.load_all
    names = Dir[File.join(PATH, '**/*.yml')].map do |f|
      f.delete_prefix("#{PATH}/").delete_suffix('.yml')
    end
    ActiveRecord::FixtureSet.create_fixtures(PATH, names)
  end
end
