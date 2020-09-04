class AuthenticationService

  class << self

    ##
    # Generate a token that contains the otp_auth_key.
    # A client must return this token (which contains the embedded otp_auth_key) AND the correct OTP code
    # to successfully authenticate. This helps prevent man-in-the-middle attacks by ensuring that only this
    # client that can authenticate the OTP code with it.
    # Note: if user is nil, we generate a fake token so as to ward off unruly hackers.
    #
    def otp_auth_key_for(user)
      if user.present?
        user.most_recent_token.otp_auth_key
      else
        AuthToken.new.new_otp_auth_key
      end
    end

    ##
    # Send a pin message to the user
    #
    # @param [User] user the user model to send the pin to
    # @param [String] app_name name of the app to display in the message
    #
    # @return [String] user auth token
    #
    def send_pin(user, app_name)
      SlackPinService.new(user).send_otp(app_name)

      pin = user.most_recent_token.otp_code

      if user.mobile.present?
        TwilioService.new(user).sms_verification_pin(app_name, pin: pin)
      elsif user.email.present?
        SendgridService.new(user).send_pin_email(pin: pin)
      end

      otp_auth_key_for(user)
    rescue => e
      raise Goodcity::ExternalServiceError.new(e.message.try(:split, ".").try(:first))
    end
  end
end
