require 'goodcity/cleanup'

namespace :goodcity do
  namespace :packages_locations do

    desc "Delete dispatched packages_locations"
    task delete_dispatched_locations: :environment do
      Goodcity::Cleanup.delete_dispatched_packages_locations
    end

  end
end