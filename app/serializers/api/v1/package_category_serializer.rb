module Api::V1

  class PackageCategorySerializer < ApplicationSerializer
    # embed :ids, include: true
    attributes :id, :name, :parent_id, :package_type_codes

    def name__sql
      "name_#{current_language}"
    end

    def package_type_codes
      object.package_types.pluck(:code).join(',')
    end

    def package_type_codes__sql
      " (SELECT string_agg(package_types.code, ',')
        FROM package_types, package_sub_categories
        where package_types.id = package_sub_categories.package_type_id AND
          package_categories.id = package_sub_categories.package_category_id
        GROUP BY package_sub_categories.package_category_id) "
    end
  end

end
