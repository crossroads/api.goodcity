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

    def login
      # @result = User.creation_with_auth(step2_auth_params)
    end

    def is_unique_mobile_number
      is_unique = User.check_for_mobile_uniqueness(params[:mobile]).zero?
      render json: { is_unique_mobile: is_unique }
    end

    def validate_pin
      user       = warden.authenticate! :pin
      json_token = generate_enc_session_token(user) if user
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

    def validate_token
      token = request.headers['Authorization'].split(' ').last
      decode_session_token(token)
    end

    # Generate an encoded Json Web Token to send to client app
    # on successful completion of the authentication process
    def generate_enc_session_token(user)
      JWT.encode({"mobile" => user.mobile,
        "otp_secret_key" => user.friendly_token},
        SECRET_KEY,
        HMAC_SHA_ALGO)
    end

    # Decode the json web token when we receive it from the client
    # before proceeding ahead
    def decode_session_token(token)
      begin
        JWT.decode(token, SECRET_KEY,HMAC_SHA_ALGO)
      rescue JWT::DecodeError
        render nothing: true, status: :unauthorized
      end
    end
  end
end
