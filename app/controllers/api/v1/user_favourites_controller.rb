module Api
  module V1
    class UserFavouritesController < Api::V1::ApiController
      load_and_authorize_resource :user_favourite, parent: false

      resource_description do
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      api :GET, '/v1/user_favourites', "Fetches user_favourites"
      def index
        user_favourites = @user_favourites.where(favourite_type: params[:types])
        render json: user_favourites
      end
    end
  end
end