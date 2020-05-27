# rake goodcity:add_permissions_for_roles

namespace :goodcity do
  task add_permissions_for_roles: :environment do
    RolePermissionsMappings.apply!
  end
end
