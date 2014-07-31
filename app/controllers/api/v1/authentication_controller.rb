module Api::V1
  class AuthenticationController < Api::V1::ApiController
    skip_before_action :validate_token,
      only: [:is_mobile_exist, :is_unique_mobile_number,:signup, :verify,
      :resend]

    def resend
      (token_header != "undefined" && token_header.present?) ? search_by_token : search_by_mobile
    end

    def signup
      @result = User.creation_with_auth(auth_params)
      if @result.class == User
        warden.set_user(@result)
        render json: {token: @result.friendly_token,
          msg: I18n.t(:success)}, status: :ok
      else
        render json: {token: "", msg: @result}, status: :forbidden
      end
    end

    def verify
      user       = warden.authenticate! :pin
      json_token = generate_enc_session_token(user.mobile, token_header) if user
      render json: {jwt_token: (user.present? ? json_token : "")}
    end

    def is_unique_mobile_number
      render json: { is_unique_mobile: unique_user.blank? }
    end

    def unique_user
      User.check_for_mobile_uniqueness(params[:mobile])
    end

    private
    def auth_params
      params.require(:user_auth).permit(:mobile, :first_name, :last_name)
    end

    def search_by_mobile
      user = unique_user
      if user.present?
        user.send_verification_pin
        render json: { mobile_exist: true ,
          token: user.friendly_token}, status: :ok
      else
        render json: { mobile_exist: false, token: "" }, status: :unauthorized
      end
    end

    def search_by_token
      user= User.find_user_based_on_auth(token_header)
      if user.send_verification_pin
        render json: { token: token_header,
          msg: I18n.t('auth.pin_sent') }, status: :ok
      else
        render json: { token: "",
          msg: I18n.t('auth.mobile_required') }, status: :unauthorized
      end
    end
  end
end
