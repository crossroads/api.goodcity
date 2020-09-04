module Api
  module V2
    class Ability < ::Ability

      def initialize(user, role: nil)
        @role             = role
        @user_permissions = role.permissions.map(&:name) if role.present?
        
        super(user)
      end

      # -----------------
      # Access definitions
      # -----------------

      def public_abilities
        # todo
      end

      def define_abilities
        # todo   
      end
    end
  end
end