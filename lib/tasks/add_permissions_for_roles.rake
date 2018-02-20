# rake goodcity:add_permissions_for_roles

namespace :goodcity do
  task add_permissions_for_roles: :environment do

    ROLES_AND_PERMISSIONS = {
      "Reviewer" => ['can_manage_packages', 'can_manage_offers', 'can_manage_deliveries',
        'can_manage_orders', 'can_manage_order_transport', 'can_manage_holidays',
        'can_check_organisations', 'can_manage_packages_locations', 'can_manage_items'],
      "Supervisor" => ['can_manage_packages', 'can_manage_offers', 'can_manage_deliveries',
        'can_manage_orders', 'can_manage_order_transport', 'can_manage_holidays',
        'can_check_organisations', 'can_manage_packages_locations', 'can_manage_items',
        'can_manage_users'],
      "api-write" => [],
      "System" => [],
      "Charity" => []
    }

    ROLES_AND_PERMISSIONS.each_pair do |role_name, permission_names|
      role = Role.where(name: role_name).first_or_create
      if role
        permission_names.each do |permission_name|
          permission = Permission.where(name: permission_name).first_or_create
          RolePermission.where(role: role, permission: permission).first_or_create
        end
      end
    end
  end
end
