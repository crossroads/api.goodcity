class ApplicationController < ActionController::API
  include CanCan::ControllerAdditions
  before_action :validate_token, except: [:new, :validate_pin, :is_unique_mobile_number]
  helper_method :current_user
  def warden
    env["warden"]
  end

  def unauthenticated(status_message = "Token invalid")
    render json: {token: "", error: "#{status_message}"}
  end

  private
    def current_user
      warden.user
    end

    def token_header
      request.headers['Authorization'].split(' ').last
    end

    #TODO: Shivani need to fail the auth if value returned is FALSE
    def validate_token
      jwt_decoded_json = decode_session_token(token_header)
      auth_status = validate_authenticity_of_jwt(jwt_decoded_json)
      auth_status[:status] unless auth_status[:value] == false
    end

    #Generate an encoded Json Web Token to send to client app
    #on successful completion of the authentication process
    def generate_enc_session_token(user_mobile, user_otp_skey)
       cur_time = Time.now
        JWT.encode({"iat" => cur_time.to_i,
                  "iss" => ISSUER,
                  "exp" => (cur_time + 14.days).to_i,
                  "mobile"  => user_mobile,
                  "otp_secret_key"  => user_otp_skey},
                  SECRET_KEY,
                  HMAC_SHA_ALGO)
    end

    # Decode the json web token when we receive it from the client
    # before proceeding ahead
    def decode_session_token(token)
      #TODO: while decoding time use Time.at(iat)
      begin
        JWT.decode(token, SECRET_KEY,HMAC_SHA_ALGO)
      rescue JWT::DecodeError
        render nothing: true, status: :unauthorized
      end
    end
    #Is the JWT token is authentic or not. If authentic then allow to login
    #exp should be greater than todays date and time
    #iat should be less than the current time and date
    #Time.now should not be more than 14 days,that means time.now and exp should not be equal
    def validate_authenticity_of_jwt(jwt_decoded_json)
      cur_time = Time.now
      iat_time = Time.at(jwt_decoded_json["iat"])
      exp_time = Time.at(jwt_decoded_json["exp"])
      byebug
      case cur_time.present?
        when (iat_time < cur_time && exp_time >= cur_time && iat_time < exp_time) == true
              byebug
              {status: "It is a valid token", value: true}
        when iat_time > cur_time == true
              byebug
              {status: "It is not a valid token, issue date is not correct", value: false}
        when exp_time < cur_time == true
                byebug
               {status: "Token has expired", value: false}
        when iat_time < exp_time == true
               byebug
               {status: "Token is not authentic and does not look like generated from the app", value: false}
        else
              {status: "Invalid token", value: false}
      end
    end
end

