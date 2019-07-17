# to run this rake task run the following command.
# rake 'goodcity:remove_permission_from_role[can_manage_orders, Charity]'

namespace :goodcity do
  task :remove_permission_from_role, [:permission, :role_name] => [:environment] do |task, args|
    Permission.find_by(name: args.permission)
    .role_permissions.where(role_id: Role.find_by(name: args.role_name).id)
    .first&.destroy
  end
end
