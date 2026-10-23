module Api::V1
  # Full editable shape of a PackageType for the admin editor
  # (show / create / update). The shared PackageTypeSerializer (index) is untouched.
  class PackageTypeAdminSerializer < ApplicationSerializer
    attributes :id, :code,
               :name_en, :name_zh_tw, :other_terms_en, :other_terms_zh_tw,
               :description_en, :description_zh_tw,
               :subform, :location_id, :department,
               :allow_package, :allow_pieces, :allow_box, :allow_pallet,
               :allow_requests, :visible_in_selects, :allow_expiry_date,
               :default_value_hk_dollar, :customs_value_usd,
               :length, :width, :height,
               :package_category_ids, :subpackage_types,
               :in_use, :item_count, :package_count, :request_count,
               :set_count, :deletable

    def package_category_ids
      object.package_categories_package_types.pluck(:package_category_id)
    end

    def subpackage_types
      object.subpackage_types.includes(:child_package_type).map do |sub|
        child = sub.child_package_type
        {
          subpackage_type_id: sub.subpackage_type_id,
          is_default: sub.is_default,
          child_code: child.try(:code),
          child_name: child.try(:name_en)
        }
      end
    end

    def item_count
      object.items.count
    end

    def package_count
      object.packages.count
    end

    def request_count
      object.goodcity_requests.count
    end

    def in_use
      item_count.positive? || package_count.positive? || request_count.positive?
    end

    def set_count
      PackageSet.where(package_type_id: object.id).count
    end

    # Nothing points at this type now, soft-deleted items and packages included (PackageType#usage_counts),
    # so DELETE ?hard=true may remove it. Anything else may only be retired. (in_use and the counts
    # above are the CURRENT use the editor shows; they leave soft-deleted rows out, as before.)
    def deletable
      object.usage_counts.values.all?(&:zero?)
    end
  end
end
