# frozen_string_literal: true

# The factories look up rows from spec/fixtures (districts, locations, the bystander
# user), so load them once, before any scenario. This runs outside the DatabaseCleaner
# transaction, so the rows persist across scenarios. CI runs cucumber against a fresh
# database, so nothing else would provide them.
require Rails.root.join('spec/support/fixture_loader')

FixtureLoader.load_all
