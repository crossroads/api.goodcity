# to run this rake task run the following command.
# rake goodcity:remove_permission_from_role permission=permission_name role=role_name

namespace :goodcity do
  task remove_permission_from_role: :environment do
    Permission.find_by(name: ENV["permission"])
      .role_permissions.where(role_id: Role.find_by(name: ENV["role"]).id)
      .first&.destroy
  end
end
