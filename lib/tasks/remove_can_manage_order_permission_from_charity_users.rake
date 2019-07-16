namespace :goodcity do
  task remove_can_manage_order_permission_from_charity_users: :environment do
    role_permission = Permission.find_by(name:"can_manage_orders").role_permissions.where(role_id: Role.find_by(name: "Charity").id).first

    role_permission.destroy if role_permission
  end
end
