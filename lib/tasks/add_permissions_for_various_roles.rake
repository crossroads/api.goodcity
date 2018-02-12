#rake goodcity:add_permissions_for_various_roles
namespace :goodcity do
  task add_permissions_for_various_roles: :environment do
    #need to modify this hash as per staging or live records
    PERMISSION_NAME_AND_ID_MAPPING = {
      'System' => 1,
      'api-write' => 2,
      'Reviewer' => 3,
      'Supervisor' => 4,
      'Charity Manager' => 5,
      'Charity' => 6
    }

    ROLES_AND_PERMISSIONS = {
      "Reviewer" => ['can_manage_packages', 'can_manage_offers', 'can_manage_deliveries',
        'can_manage_orders', 'can_manage_order_transport', 'can_manage_holidays',
        'can_check_organisations', 'can_manage_packages_locations']
    }

    ROLES_AND_PERMISSIONS.each_pair do |role_name, permissions|
      role = Role.where(name: role_name).first_or_create
      users = User.where(permission_id: PERMISSION_NAME_AND_ID_MAPPING[role_name])

      permissions.each do |permission_name|
        permission = Permission.where(name: permission_name).first_or_create
        users.each do |user|
          UserRolePermission.where(role: role, permission: permission, user: user).first_or_create
        end
      end
    end
  end
end
