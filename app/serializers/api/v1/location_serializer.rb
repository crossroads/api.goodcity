module Api::V1
  class LocationSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :building, :area, :packages_count, :printer_name

    # Distinct packages held at this location (computed; no schema change)
    def packages_count
      object.packages_locations.map(&:package_id).uniq.size
    end

    def printer_name
      object.printer&.name
    end
  end
end
