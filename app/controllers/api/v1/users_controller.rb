module Api::V1
  class UsersController < Api::V1::ApiController
    load_and_authorize_resource :user, parent: false

    resource_description do
      short 'List Users'
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    api :GET, '/v1/users', "List all users"
    param :ids, Array, of: Integer, desc: "Filter by user ids e.g. ids = [1,2,3,4]"
    description <<-EOS
      Note: in accordance with permissions, users will only be able to list users they are allowed to see.
      For a donor, this will be just themselves. For administrators, this will be all users.
    EOS
    def index
      @users = @users.find( params[:ids].split(",") ) if params[:ids].present?
      render json: @users, each_serializer: serializer
    end

    api :GET, '/v1/users/1', "List a user"
    description "Returns information about a user. Note image may be empty if user is not a reviewer."
    def show
      render json: @user, serializer: serializer
    end

    api :PUT, '/v1/users/1', "Update user"
    param :user, Hash, required: true do
      param :last_connected, String, desc: "Time when user last connected to server."
      param :last_disconnected, String, desc: "Time when user disconnected from server."
    end
    def update
      @user.update_attributes(user_params)
      render json: @user, serializer: serializer
    end

    private

    def serializer
      Api::V1::UserSerializer
    end

    def user_params
      attributes = [:last_connected, :last_disconnected]
      attributes.concat([:permission_id]) if User.current_user.supervisor?
      params.require(:user).permit(attributes)
    end
  end
end
