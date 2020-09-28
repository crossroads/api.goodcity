module Api
  module V2
    class Ability < ::Ability

      def initialize(user, role: nil)
        @role = role        
        super(user)
      end

      def user_permissions
        return [] unless @user.present? && @role.present?
        @user_permissions = role.permissions.map(&:name)
      end

      # -----------------
      # Access definitions
      # -----------------

      def public_abilities
        # todo
      end

      def define_abilities
        users_abilities
      end

      def users_abilities
        can [:me], User
      end
    end
  end
end