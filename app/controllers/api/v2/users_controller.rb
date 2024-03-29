module Api
  module V2
    class UsersController < Api::V2::ApiController
      load_and_authorize_resource :user, parent: false

      resource_description do
        short 'User crud operations'
        formats ['json']
        error 401, 'Unauthorized'
        error 404, 'Not Found'
        error 422, 'Validation Error'
        error 500, 'Internal Server Error'
      end

      api :GET, '/v2/users/me', 'Returns the currently logged in user'
      description <<-EOS
        Returns the currently logged in user based on the attached JWT

        ===Response status codes
        * 200 - returned regardless of whether mobile number exists or not
        * 401 - returned if unauthenticated
      EOS
      param :include,
            String,
            required: false,
            desc: 'A comma separated list of the attributes/relationships to include in the response'
      error 401, 'Unauthorized'
      def me
        render json: serialize(current_user)
      end

      api :POST, '/v2/users/update_mobile_number', 'Update'
      description <<-EOS
        Updates the phone number

        ===Params
        * token - JWT token which encapsulates mobile number and otp_auth_key
        * user_id - User

        ===Response status codes
        * 200 - returned if phone number is updated
        * 422 - returned in case of any error
      EOS
      def update_phone_number
        @user = AuthenticationService.authenticate!({ 'otp_auth_key': params[:token],
                                                      'pin': params[:pin] }.with_indifferent_access,
                                                    strategy: :pin_jwt)

        mobile = Token.new(bearer: params[:token]).read('mobile')

        @user.update!(mobile: mobile)
        render json: serialize(@user)
      end

      private

      def serialize(records)
        Api::V2::UserSerializer.new(records, serializer_options(:user))
      end
    end
  end
end
