module Api::V1
  class AuthenticationController < Api::V1::ApiController

    skip_before_action :validate_token,
      only: [:is_mobile_exist, :is_unique_mobile_number,:signup, :verify,
      :resend]

    def resend
      token.valid? ? search_by_token : search_by_mobile
    end

    def signup
      @result = User.creation_with_auth(auth_params)
      if @result.class == User
        warden.set_user(@result)
        render json: {token: @result.friendly_token,
          message: I18n.t(:success)}, status: :ok
      else
        throw(:warden, {status: :forbidden,
          message: {
          text:  @result,
          token: ""}
      })
      end
    end

    def verify
      user = warden.authenticate! :pin
      if warden.authenticated?
        json_token = user.present? ? token.generate(mobile: user.mobile) : ""
        render json: {jwt_token: json_token}, status: :ok
      else
        throw(:warden, {status: :unauthorized,
          message: {
            text: I18n.t('token.invalid'),
            jwt_token: ""}
        })
      end
    end

    def is_unique_mobile_number
      render json: { is_unique_mobile: unique_user.blank? }, status: :ok
    end

    def unique_user
      User.check_for_mobile_uniqueness(params[:mobile]).first
    end

    private

    def auth_params
      params.require(:user_auth).permit(:mobile, :first_name, :last_name)
    end

    def search_by_mobile
      if (user = unique_user).present?
        user.send_verification_pin
        render json: { mobile_exist: true ,
          token: user.friendly_token}, status: :ok
      else
        throw(:warden, {status: :unauthorized,
          message: {
            text: I18n.t('auth.mobile_doesnot_exist'),
            token: "",
            mobile_exist: false}
        })
      end
    end

    def search_by_token
      if token.valid? && (user = User.find_all_by_otp_secret_key(token.header).first).present?
        user.send_verification_pin
        render( json: { token: token.header, message: I18n.t('auth.pin_sent') }, status: :ok)
      else
        throw(:warden, {status: :unauthorized, message: { text:  I18n.t('token.invalid'), token: ""} })
      end
    end

  end
end
