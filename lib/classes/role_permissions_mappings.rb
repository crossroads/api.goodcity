# frozen_string_literal: true

# role_permissions mapper
class RolePermissionsMappings
  def self.apply!
    new.apply!
  end

  def apply!
    sync_roles_and_permissions
  end

  private

  def add_permission_to_role(role_name, permission_names)
    role = Role.where(name: role_name).first_or_create
    permission_names.each do |permission_name|
      permission = Permission.where(name: permission_name).first_or_create
      RolePermission.where(role: role, permission: permission).first_or_create
    end
  end

  def load_permissions_roles
    YAML.load_file("#{Rails.root}/db/permissions_roles.yml")
  end

  def remove_missing_roles_and_permissions(role_name, permission_names)
    RolePermission.joins(:role).joins(:permission)
                  .where('roles.name' => role_name)
                  .where.not('permissions.name' => permission_names)
                  .delete_all
  end

  def sync_roles_and_permissions
    role_permissions = load_permissions_roles
    role_permissions.each_pair do |role_name, permission_names|
      permission_names.flatten!
      remove_missing_roles_and_permissions(role_name, permission_names)
      add_permission_to_role(role_name, permission_names)
    end
  end
end
