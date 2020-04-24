# rake goodcity:add_permissions_for_roles

namespace :goodcity do
  task add_permissions_for_roles: :environment do

    permissions_roles = YAML.load_file("#{Rails.root}/db/permissions_roles.yml")
    permissions_roles.each_pair do |role_name, permission_names|
      permission_names.flatten!
      # Remove
      RolePermission.joins(:role).joins(:permission).where("roles.name" => role_name).where.not("permissions.name" => permission_names).delete_all

      if(role = Role.where(name: role_name).first_or_create)
        permission_names.each do |permission_name|
          permission = Permission.where(name: permission_name).first_or_create
          RolePermission.where(role: role, permission: permission).first_or_create
        end
      end
    end
  end
end
