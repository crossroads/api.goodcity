module Api::V1
  class PackageCategorySerializer < ApplicationSerializer
    # embed :ids, include: true
    attributes :id, :parent_id, :package_type_codes
    attribute "name_#{current_language}".to_sym

    def package_type_codes
      object.package_types.pluck(:code).join(',')
    end
  end
end
