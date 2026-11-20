module Api::V1
  # One containment row for the goods-types editor: the parent type (package_type_id) may hold the
  # child type (subpackage_type_id). Returned by the containment member actions on PackageTypesController.
  class SubpackageTypeSerializer < ApplicationSerializer
    attributes :id, :package_type_id, :subpackage_type_id, :is_default, :child_code, :child_name

    def child_code
      object.child_package_type.try(:code)
    end

    def child_name
      object.child_package_type.try(:name_en)
    end
  end
end
