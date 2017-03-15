#use 'rake populate_organisation:organisation' to create or update organisation details

require "goodcity/organisation_populator"

namespace :populate_organisation do
  task organisation:  :environment do
    Goodcity::OrganisationPopulator.new.populate_organisation_db
  end
end
