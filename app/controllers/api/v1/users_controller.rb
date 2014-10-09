module Api::V1
  class UsersController < Api::V1::ApiController
    load_and_authorize_resource :user, parent: false

    resource_description do
      short 'List Users.'
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    api :GET, '/v1/users', "List all users"
    param :ids, Array, of: Integer, desc: "Filter by user ids e.g. ids = [1,2,3,4]"
    def index
      @users = @users.find( params[:ids].split(",") ) if params[:ids].present?
      render json: @users, each_serializer: serializer
    end

    api :GET, '/v1/users/1', "List an user"
    def show
      render json: @user, serializer: serializer
    end

    private

    def serializer
      Api::V1::UserSerializer
    end

  end
end
