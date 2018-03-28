module Api
  module V1
    class UserRolesController < ApplicationController
      load_and_authorize_resource :user_role, parent: false

      resource_description do
        short "Get User roles."
        formats ["json"]
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 500, "Internal Server Error"
      end

      # def index
      #   # @user_roles = UserRole.all
      #   render_object_with_cache(@user_roles, params[:ids])
      # end

      api :POST, "/v1/user_role", "Create a user role"
      param_group :user_role
      def create
        save_and_render_object_with_errors(@user_role)
      end

      private

      def organisations_user_params
        params.require(:user_role).permit(:user_id, :role_id)
      end

      def serializer
        Api::V1::UserRoleSerializer
      end
    end
  end
end
