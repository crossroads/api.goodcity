module Api::V1
  # Locations admin screen only (docs/superpowers/specs/2026-10-10-locations-admin-design.md §7.3).
  # NOT the shared LocationSerializer — that stays { id, building, area } so the ~9 serializers that embed
  # a location (package, packages_location, stocktake, stockit_item, orders_package, package_type, ...) and the
  # legacy stock app's GET /locations are byte-unchanged. The controller uses this serializer only on the admin
  # paths: #update, and #index when the explicit `with_counts` param is present.
  class LocationAdminSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :building, :area, :packages_count, :printer_name, :retired_at, :in_use

    # Distinct packages held at this location (computed; no schema change).
    # A COUNT(DISTINCT package_id) per row, not a load of the packages_locations rows — the admin list is a
    # small, bounded set of locations (design D3), and the controller eager-loads :printer to kill that N+1.
    def packages_count
      object.packages_locations.distinct.count(:package_id)
    end

    def printer_name
      object.printer&.name
    end

    # Whether DELETE would be refused (a foreign key still points here): the screen then offers Retire, not Delete.
    # The admin index computes the set once for every row (`in_use_ids`); a single row (PATCH reply) asks itself.
    def in_use
      ids = options[:in_use_ids]
      ids ? ids.include?(object.id) : object.in_use?
    end
  end
end
