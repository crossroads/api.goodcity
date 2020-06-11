module ManageUserRoles
  extend ActiveSupport::Concern

  included do

    def update_roles_for_user(user, role_ids)
      return unless self.can_update_roles_for_user?(user)

      allowed_role_ids = self.update_allowed_on_roles.where(id: role_ids).pluck(:id)
      user.create_or_remove_user_roles(allowed_role_ids)
    end

    def can_update_roles_for_user?(other_user)
      self != other_user &&
      self.max_role_level >= other_user.max_role_level
    end

    def max_role_level
      self.roles.maximum("level") || 0
    end

    def update_allowed_on_roles
      Role.where("level <= ?", max_role_level)
    end

    def create_or_remove_user_roles(role_ids)
      role_ids = role_ids || []
      remove_old_user_roles(role_ids)

      role_ids.each do |role_id|
        user_roles.where(role_id: role_id).first_or_create
      end
    end

    private

    def remove_old_user_roles(role_ids)
      role_ids_to_remove = roles.pluck(:id) - role_ids
      user_roles.where("role_id IN(?)", role_ids_to_remove).destroy_all
    end

  end
end

