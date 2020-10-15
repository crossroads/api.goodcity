class AuthenticationService

  module Strategies
    @@strategies        = {}
    @@default_strategy  = nil

    module_function

    def add(key, klass)
      @@strategies[key] = klass
    end

    def load(key, *args)
      @@strategies[key].new(*args)
    end

    def default_strategy(key)
      @@default_strategy = key if key
      @@default_strategy
    end
  end

  class << self

    ##
    # Generate a token that contains the otp_auth_key.
    # A client must return this token (which contains the embedded otp_auth_key) AND the correct OTP code
    # to successfully authenticate. This helps prevent man-in-the-middle attacks by ensuring that only this
    # client that can authenticate the OTP code with it.
    #
    #
    def otp_auth_key_for(user, refresh: false)
      user.refresh_auth_token! if refresh
      user.most_recent_token.otp_auth_key
    end

    ##
    # Generates a fake token so as to ward off unruly hackers
    #
    # @return [String] an anonymous auth token
    #
    def fake_otp_auth_key
      AuthToken.new.new_otp_auth_key
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

    ##
    # Registers a new user
    #
    # @param [Hash] user_params the user parameters to intitialize the user with
    # @option user_params [String] :mobile the mobile number of the new user /\+852\d{8}/
    # @option user_params [String] :email the email of the new user
    # @option user_params [String] :first_name the user's name
    # @option user_params [String] :last_name the user's last name
    # @option user_params [Hash] :address_attributes the nested attributes to initialize the address with
    #
    # @return [User] the new user
    #
    def register_user(user_params)
      mobile, email = user_params.values_at(:mobile, :email)

      raise Goodcity::MissingParamError.new('mobile/email') if mobile.blank? && email.blank?

      downcase_email = email&.downcase

      raise Goodcity::DuplicateRecordError if mobile.present? && User.find_by(mobile: mobile).present?
      raise Goodcity::DuplicateRecordError if email.present?  && User.find_by('LOWER(email) = (?)', downcase_email).present?

      user = User.new(user_params)
      user.email = downcase_email
      user.save!
      user
    end

    ##
    # Generates a Token for the user
    #
    # @param [User] user the user to permit
    # @param [Integer] api_version: the api version to allow
    #
    # @return [String] jwt token
    #
    def generate_token(user, api_version:)
      Token.new.generate(user_id: user.id, metadata: {
        type:         Token::Types::API,
        api_version:  "v#{api_version}"
      })
    end

    #
    # Authenticates a user with the selected strategy
    #
    # @param [Hash] params the request post data
    # @param [Goodcity::Authentication::Strategies::BaseStrategy] strategy the auth strategy to use
    #
    # @throws Goodcity::BaseError
    #
    # @return [User] the authenticated user
    #
    def authenticate!(params, strategy: Strategies.default_strategy)
      instance = Strategies.load(strategy, params)

      raise Goodcity::InvalidParamsError unless instance.valid?

      begin
        user ||= instance.execute
        raise Goodcity::UnauthorizedError unless user.present?
        return user
      rescue StandardError => e
        raise e if e.is_a?(Goodcity::BaseError)
        raise Goodcity::UnauthorizedError.with_text(e.try(:message))
      end
    end

    #
    # Authenticates a user with the selected strategy
    #
    # @param [Hash] params the request post data
    # @param [Goodcity::Authentication::Strategies::BaseStrategy] strategy the auth strategy to use
    #
    # @return [User|nil] the authenticated user or nil if invalid
    #
    def authenticate(params, strategy: Strategies.default_strategy)
      begin
        authenticate!(params, strategy: strategy)
      rescue
        nil
      end
    end
  end
end
