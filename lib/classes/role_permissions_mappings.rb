# frozen_string_literal: true

# role_permissions mapper
class RolePermissionsMappings
  def self.apply!
    new.apply!
  end

  def apply!
    puts('Starting Role Permission mappings')
    sync_roles_and_permissions
    puts('Finished successfully.')
  end

  private

  def add_permission_to_role(role_name, permission_names)
    role = Role.where(name: role_name).first_or_create
    permission_names.each do |permission_name|
      permission = Permission.where(name: permission_name).first_or_create
      record = RolePermission.find_by(role: role, permission: permission)
      unless record
        RolePermission.create(role: role, permission: permission)
        puts("Added #{permission.name} for #{role_name}")
      end
    end
  end

  def remove_additional_permissions_for_role(role_name, permission_names)
    # Delete the role_permissions records that are not present in permissions_roles.yml
    # for the respective roles
    role_permissions = RolePermission.joins(:role).joins(:permission)
                                     .where('roles.name' => role_name)
                                     .where
                                     .not('permissions.name' => permission_names)
    return if role_permissions.empty?

    permission_names = role_permissions.map { |p| p.permission.name }
    role_permissions.delete_all
    puts("Removed #{permission_names} from #{role_name}")
  end

  def sync_roles_and_permissions
    role_permissions = YAML.load_file("#{Rails.root}/db/permissions_roles.yml")
    role_permissions.each_pair do |role_name, permission_names|
      ActiveRecord::Base.transaction do
        permission_names.flatten!
        remove_additional_permissions_for_role(role_name, permission_names)
        add_permission_to_role(role_name, permission_names)
      end
    rescue ActiveRecord::RecordInvalid
      puts("Encountered errors while adding #{permission_names} to #{role_name}")
    end
  end
end
