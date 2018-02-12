#rake goodcity:add_permissions_for_various_roles
namespace :goodcity do
  task add_permissions_for_various_roles: :environment do

    ROLES_AND_PERMISSIONS = {
      "Reviewer" => ['can_manage_packages', 'can_manage_offers', 'can_manage_deliveries',
        'can_manage_orders', 'can_manage_order_transport', 'can_manage_holidays',
        'can_check_organisations', 'can_manage_packages_locations']
    }

    User.find_each do |user|
      existing_permission = Permission.find_by_id(user.permission_id)

      if existing_permission
        existing_permission_name = existing_permission.try(:name)
        role = Role.where(name: existing_permission_name).first_or_create

        ROLES_AND_PERMISSIONS[existing_permission_name].each do |permission_name|
          new_permission = Permission.where(name: permission_name).first_or_create
          UserRolePermission.where(role: role, permission: new_permission, user: user).first_or_create
        end
      end
    end
  end
end
