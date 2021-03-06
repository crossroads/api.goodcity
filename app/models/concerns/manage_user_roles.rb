module ManageUserRoles
  extend ActiveSupport::Concern

  ##
  # Allow user to update roles of other users based on their own max role level.
  #
  # User's max role level is highest level value from all his assigned roles.
  # User has ability to update roles of other users who have max role level same as current-user or
  # less that it.
  # Also user has access to roles which has level less than user's max role level.
  #
  # Example:
  # Available Roles: Reviewer(level-5), Supervisor(level-10), Donor(level-1)
  # Consider User has roles Supervisor and Reviewer, hence User's max role level 10
  # User has access to only to Donor and Reviewer roles, can not access Supervisor role.
  # User can update roles of other users who have max role level <= 5.
  #

  included do

    def assign_role_for_user(user_id: , role_id: , expires_at: nil)
      return unless can_update_roles_for_user?(user_id)
      assign_role(user_id, role_id, expires_at) if accessible_role?(role_id)
    end

    def remove_role_for_user(user_role)
      return unless can_update_roles_for_user?(user_role.user_id)
      user_role.destroy if accessible_role?(user_role.role_id)
    end

    def accessible_role?(role_id)
      Role.allowed_roles(max_role_level).pluck(:id).include?(role_id.to_i)
    end

    def can_update_roles_for_user?(other_user_id)
      other_user = User.find_by(id: other_user_id)
      self != other_user &&
        self.max_role_level >= other_user.max_role_level &&
        can_manage_user_roles?
    end

    def max_role_level
      active_roles.maximum("level") || 0
    end

    def assign_role(user_id, role_id, expires_at)
      user_role = UserRole
          .where(user_id: user_id, role_id: role_id)
          .first_or_initialize
      user_role.expires_at = expires_at
      user_role.save
      user_role
    end

    def can_manage_user_roles?
      user_permissions_names.include?("can_manage_user_roles")
    end

  end
end

