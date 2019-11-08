namespace :goodcity do
  namespace :packages_locations do

    desc "Delete dispatched packages_locations"
    task delete_dispatched_locations: :environment do
      # Use delete instead of destroy so we don't fire push updates
      location_id = Location.dispatch_location.id
      PackagesLocation.where(location_id: location_id).delete_all
    end

  end
end