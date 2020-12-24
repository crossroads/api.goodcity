module Api
  module V2
    class Ability < ::Ability

      def initialize(user, role: nil)
        @role = role        
        super(user)
      end

      def user_permissions
        return [] unless @user.present?
        @user_permissions ||= @role.present? ? @role.permissions.map(&:name) : super
      end

      # -----------------
      # Access definitions
      # -----------------

      def public_abilities
        # todo
      end

      def define_abilities
        shareable_abilities
        users_abilities
      end

      def users_abilities
        can [:me], User
      end

      def shareable_abilities
        can :manage, Shareable, { resource_type: 'Offer' }      if can_manage_offers?
        can :manage, Shareable, { resource_type: 'Item' }       if can_manage_items?
        can :manage, Shareable, { resource_type: 'Package' }    if can_manage_packages?
      end
    end
  end
end
