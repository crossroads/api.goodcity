module Api
  module V1
    class UserRolesController < Api::V1::ApiController
      load_and_authorize_resource :user_role, parent: false

      def_param_group :user_role do
        param :user_role, Hash, required: true do
          param :user_id, String, required: true
          param :role_id, String, required: true
          param :expires_at, String, required: false, allow_nil: true
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
        current_user.remove_role_for_user(@user_role)
        render json: {}
      end

      api :POST, "/v1/user_roles", "Add an user_role"
      param_group :user_role
      def create
        user_id, role_id, expires_at = params["user_role"].values_at('user_id', 'role_id', 'expires_at')

        @user_role = current_user.assign_role_for_user(
          user_id: user_id,
          role_id: role_id,
          expires_at: expires_at
        )

        if @user_role
          save_and_render_object(@user_role)
        else
          render json: {}, status: 401
        end
      end

      private

      def serializer
        Api::V1::UserRoleSerializer
      end

      def user_role_params
        params.require(:user_role).permit(:role_id, :user_id, :expires_at)
      end
    end
  end
end
