# frozen_String_literal: true

# Looks up rows from spec/fixtures so factories can reuse them for incidental
# associations instead of building new records. Returns nil outside the test suite
# (e.g. rake db:demo), where no fixtures are loaded, so callers can fall back to a factory:
#
#   user { FixtureRecords.find(User, :bystander) || association(:user) }
#
module FixtureRecords
  def self.find(model, label)
    # FixtureSet is only loaded by the test framework
    return unless defined?(ActiveRecord::FixtureSet)

    model.find_by(id: ActiveRecord::FixtureSet.identify(label))
  end
end
