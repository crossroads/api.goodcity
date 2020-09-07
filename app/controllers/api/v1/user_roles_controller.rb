module Api
  module V1
    class UserRolesController < Api::V1::ApiController
      load_and_authorize_resource :user_role, parent: false

      def_param_group :user_role do
        param :user_role, Hash, required: true do
          param :user_id, String
          param :role_id, String
          param :expiry_date, String, required: false, allow_nil: true
        end
      end

      def index
        @user_roles = UserRole.where(user_id: params["search_by_user_id"])
        render json: @user_roles, each_serializer: serializer
      end

      def show
        render json: @user_role, serializer: serializer
      end

      def destroy
        @user_role.destroy
        render json: {}
      end

      api :POST, "/v1/user_roles", "Add an user_role"
      param_group :user_role
      def create
        @user_role = UserRole
          .where(user_id: params["user_role"]["user_id"], role_id: params["user_role"]["role_id"])
          .first_or_initialize
        @user_role.expiry_date = params["user_role"]["expiry_date"]

        save_and_render_object(@user_role)
      end

      private

      def serializer
        Api::V1::UserRoleSerializer
      end

      def user_role_params
        params.require(:user_role).permit(:role_id, :user_id, :expiry_date)
      end
    end
  end
end
