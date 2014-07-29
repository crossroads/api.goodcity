module Api::V1
  class UsersController < Api::V1::ApiController
    skip_before_action :validate_token,
      only: [:signup, :is_unique_mobile_number, :validate_pin,
      :is_mobile_exist, :resend]
    load_and_authorize_resource :user, parent: false

    def index
      if params[:ids].present?
        @users = @users.find( params[:ids].split(",") )
      end
      render json: @users, each_serializer: serializer
    end

    def signup
      @result = User.creation_with_auth(user_auth_params)
      if @result.class == User
        warden.set_user(@result)
        render json: {token: @result.friendly_token, msg: I18n.t(:success)}, status: :ok
      else
        render json: {token: "", msg: @result}, status: :forbidden
      end
    end

    def login

    end

    def is_mobile_exist
      resend
    end

    def search_by_mobile
      user = unique_user
      if user.present?
        user.send_verification_pin
        render json: { mobile_exist: true , token: user.friendly_token}, status: :ok
      else
        render json: { mobile_exist: false, token: "" }, status: :unauthorized
      end
    end

    def search_by_token
      user= User.find_user_based_on_auth(token_header)
      if user.send_verification_pin
        render json: { token: token_header, msg: I18n.t('auth.pin_sent') }, status: :ok
      else
        render json: { token: "", msg: I18n.t('auth.mobile_required') }, status: :unauthorized
      end
    end

    def resend
      (token_header != "undefined" && token_header.present?) ?
        search_by_token : search_by_mobile
    end

    def is_unique_mobile_number
      render json: { is_unique_mobile: unique_user.blank? }
    end

    def unique_user
      User.check_for_mobile_uniqueness(params[:mobile])
    end

    def validate_pin
      user       = warden.authenticate! :pin
      json_token = generate_enc_session_token(user.mobile, token_header) if user
      render json: {jwt_token: (user.present? ? json_token : "")}
    end

    def show
      render json: @user, serializer: serializer
    end

    private

    def user_auth_params
      params.require(:user_auth).permit(:mobile, :first_name, :last_name)
    end

    def user_auth_details_params
      params.require(:user_auth_details).permit(:otp_secret_key, :pin)
    end

    def serializer
      Api::V1::UserSerializer
    end
  end
end
