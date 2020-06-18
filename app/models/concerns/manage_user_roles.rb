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
  # Available Roles: Reviewer(level-5), Supervisor(level-10), Charity(level-1), Donor(level-1)
  # Consider User has roles Charity and Reviewer, hence User's max role level 5
  # User has access to only to Charity, Donor and Reviewer roles, can not access Supervisor role.
  # User can update roles of other users who have max role level <= 5.
  #

  included do

    def update_roles_for_user(user, role_ids)
      return unless self.can_update_roles_for_user?(user)

      allowed_role_ids = Role.allowed_roles(max_role_level)
                             .where(id: role_ids)
                             .pluck(:id)
      self.update_roles_for_user(user, allowed_role_ids)
    end

    def can_update_roles_for_user?(other_user)
      self != other_user &&
      self.max_role_level >= other_user.max_role_level
    end

    def max_role_level
      self.roles.maximum("level") || 0
    end

    def update_roles_for_user(user, role_ids)
      user.roles = Role.where(id: role_ids)
    end

  end
end

