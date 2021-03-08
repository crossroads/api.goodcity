class ManageLocation
  def initialize(location_id)
    @location = Location.find_by(id: location_id)
  end

  def empty_location?
    @location.packages_locations.count.zero? &&
      @location.package_types.count.zero? &&
      PackagesInventory.where(location_id: @location.id).count.zero? &&
      Printer.where(location_id: @location.id).count.zero? &&
      Stocktake.where(location_id: @location.id).count.zero?
  end

  def self.merge_location(source_location, destination_location)
    %w[Printer Stocktake PackagesInventory PackageType PackagesLocation Package].each do |klass|
      records = Object::const_get(klass).where(location_id: source_location.id)
      records.update_all(location_id: destination_location.id)
    end
  end
end
