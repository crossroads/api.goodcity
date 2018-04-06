module Api
  module V1
    class UserRolesController < ApplicationController
      load_and_authorize_resource :user_role, parent: false

      def index
        @user_roles = UserRole.where(user_id: params["search_by_user_id"])
        render json: @user_roles, each_serializer: serializer
      end

      private

      def serializer
        Api::V1::UserRoleSerializer
      end
    end
  end
end
