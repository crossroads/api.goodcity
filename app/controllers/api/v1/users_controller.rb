module Api::V1
  class UsersController < Api::V1::ApiController

    load_and_authorize_resource :user, parent: false

    def index
      if params[:ids].present?
        @users = @users.find( params[:ids].split(",") )
      end
      render json: @users, each_serializer: serializer
    end

    def new
      @result = User.creation_with_auth(user_auth_params)
      if @result.class == User
        warden.set_user(@result)
        render json: {token: @result.friendly_token, status: "success"}
      else
        render json: {token: "", status: @result}
      end
    end

    def is_unique_mobile_number
      is_unique = User.check_for_mobile_uniqueness(params[:mobile]).zero?
      render json: { is_unique_mobile: is_unique }
    end

    def validate_pin
      user = warden.authenticate! :pin
      render json: {token: "#{user.present? ? current_user.friendly_token : ""}"}
    end

    def show
      render json: @user, serializer: serializer
    end

    private
    def user_auth_params
       params.require(:user_auth).permit(:mobile, :first_name, :last_name)
    end

    def serializer
      Api::V1::UserSerializer
    end
  end
end
