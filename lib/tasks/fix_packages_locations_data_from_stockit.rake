namespace :stockit do
  task fix_packages_locations_data_as_per_stockit: :environment do
    Package.joins(:packages_locations).group("packages.id").having("COUNT(packages_locations.location_id) > 1").find_each do |package|
      item_josn = Stockit::ItemSync.new(package).show
      stockit_item_data = JSON.parse(item_josn)
      location_id = Location.find_by(stockit_id: stockit_item_data["location_id"]).try(:id)
      unless location_id
        @packages_locations ||= Package.packages_locations
        packages_locations_to_destroy = Package.packages_locations.where.not(location_id: location_id)

        if @packages_locations.where(location_id: location_id).exists?
          packages_locations_to_destroy.destroy_all
        else
          package.packages_locations.create(quantity: package.received_quantity, location_id: location_id)
          packages_locations_to_destroy.destroy_all
        end
      end
    end
  end
end

#check packages_location quantity is equal to package.received quantity
