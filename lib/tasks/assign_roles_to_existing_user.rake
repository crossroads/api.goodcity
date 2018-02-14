#rake goodcity:assign_roles_to_existing_users
namespace :goodcity do
  task assign_roles_to_existing_users: :environment do
    User.find_each do |user|
      existing_permission = Permission.find_by_id(user.permission_id)

      if existing_permission
        existing_permission_name = existing_permission.try(:name)
        role = Role.where(name: existing_permission_name).first_or_create

        UserRole.where(role: role, user: user).first_or_create
      end
    end
  end
end
