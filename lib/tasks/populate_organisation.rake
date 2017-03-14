#use 'rake populate_organisation:organisation' to create or update organisation details

namespace :populate_organisation do
  task organisation:  :environment do
    OrganisationPopulator.new().populate_organisation_db
  end
end
