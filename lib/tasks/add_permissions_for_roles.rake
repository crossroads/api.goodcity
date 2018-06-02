# rake goodcity:add_permissions_for_roles

namespace :goodcity do
  task add_permissions_for_roles: :environment do

    permissions_roles = YAML.load_file("#{Rails.root}/db/permissions_roles.yml")
    permissions_roles.each_pair do |role_name, permission_names|
      if(role = Role.where(name: role_name).first_or_create)
        permission_names.each do |permission_name|
          permission = Permission.where(name: permission_name).first_or_create
          RolePermission.where(role: role, permission: permission).first_or_create
        end
      end
    end

  end
end

