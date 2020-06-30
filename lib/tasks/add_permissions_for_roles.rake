# rake goodcity:add_permissions_for_roles

namespace :goodcity do
  task add_permissions_for_roles: :environment do
    RolePermissionsMappings.apply!
  end
end

namespace :goodcity do
  task add_roles: :environment do
    roles = YAML.load_file("#{Rails.root}/db/roles.yml")
    roles.each do |role_name, attrs|

      if (role = Role.where(name: role_name).first_or_initialize)
        role.assign_attributes(**attrs)
        role.save
      end
    end
  end
end
