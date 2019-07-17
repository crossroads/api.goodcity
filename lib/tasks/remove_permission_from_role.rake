# to run this rake task run the following command.
# rake 'goodcity:remove_permission_from_role[can_manage_orders, Charity]'

namespace :goodcity do
  task :remove_permission_from_role, %i[permission role_name] => [:environment] do |task, args|
    role_id = Role.find_by(name: args.role_name)&.id
    permission_id = Permission.find_by(name: args.permission)&.id
    if role_id && permission_id
      RolePermission.find_by(role_id: role_id, permission_id: permission_id)&.destroy
    else
      puts "Permission not found for this role"
    end
  end
end
