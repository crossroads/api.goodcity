module Api::V1
  class UsersController < Api::V1::ApiController
    load_and_authorize_resource :user, parent: false

    def index
      if params[:ids].present?
        @users = @users.find( params[:ids].split(",") )
      end
      render json: @users, each_serializer: serializer
    end

    def show
      render json: @user, serializer: serializer
    end

    private
    def user_auth_details_params
      params.require(:user_auth_details).permit(:otp_secret_key, :pin)
    end

    def serializer
      Api::V1::UserSerializer
    end
  end
end
