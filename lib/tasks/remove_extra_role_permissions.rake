# frozen_string_literal: true

# rake goodcity:remove_extra_role_permissions

namespace :goodcity do
  task remove_extra_role_permissions: :environment do
    permissions_roles = YAML.load_file("#{Rails.root}/db/permissions_roles.yml")
    permissions_roles.each_pair do |role_name, permission_names|
      permission_names.flatten!

      # Delete the role_permissions records that are not present in permissions_roles.yml
      # for the respective roles
      RolePermission.joins(:role).joins(:permission)
                    .where('roles.name' => role_name)
                    .where.not('permissions.name' => permission_names)
                    .delete_all
    end
  end
end
