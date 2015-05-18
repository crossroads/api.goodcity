module Api::V1

  class PackageTypeSerializer < ApplicationSerializer
    embed :ids, include: true
    attributes :id, :name, :code, :other_child_packages,
      :default_child_packages

    def name__sql
      "name_#{current_language}"
    end

    def other_child_packages
      object.other_child_package_types.pluck(:code).join(',')
    end

    def default_child_packages
      object.default_child_package_types.pluck(:code).join(',')
    end

    def default_child_packages__sql
      child_packages_sql('TRUE')
    end

    def other_child_packages__sql
      child_packages_sql('FALSE')
    end

    def child_packages_sql(default_value)
      " (select string_agg(child.code, ',')
        FROM subpackage_types, package_types AS child
        WHERE package_types.id = subpackage_types.package_type_id AND
          subpackage_types.subpackage_type_id = child.id AND
          subpackage_types.is_default IS #{default_value}
        GROUP BY subpackage_types.package_type_id) "
    end
  end

end
