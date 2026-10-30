module Api::V1
  # One row of the goods-types editor's list (GET /package_types?admin=true). Lean on purpose, and
  # never cached. The per-row category ids and usage counts are computed once for the whole list
  # (PackageTypesController#admin_index) and passed in through the serializer options, so ~520 rows
  # cost a fixed handful of queries. The full editable shape (show/create/update) is
  # PackageTypeAdminSerializer; the legacy index shape is PackageTypeSerializer, untouched.
  class PackageTypeAdminRowSerializer < ApplicationSerializer
    attributes :id, :code,
               :name_en, :name_zh_tw, :other_terms_en, :other_terms_zh_tw,
               :department, :location_id, :subform,
               :allow_package, :allow_pieces, :allow_box, :allow_pallet,
               :allow_requests, :visible_in_selects, :allow_expiry_date,
               :package_category_ids, :in_use, :item_count, :package_count, :request_count

    def package_category_ids
      options.fetch(:category_ids, {}).fetch(object.id, [])
    end

    def item_count
      options.fetch(:item_counts, {}).fetch(object.id, 0)
    end

    def package_count
      options.fetch(:package_counts, {}).fetch(object.id, 0)
    end

    def request_count
      options.fetch(:request_counts, {}).fetch(object.id, 0)
    end

    def in_use
      item_count.positive? || package_count.positive? || request_count.positive?
    end
  end
end
