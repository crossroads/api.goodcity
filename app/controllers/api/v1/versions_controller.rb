module Api
  module V1
    class VersionsController < Api::V1::ApiController
      load_and_authorize_resource :version, parent: false

      resource_description do
        short 'List versions of items and related packages'
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      api :GET, '/v1/versions', "List versions of items and related packages"
      def index
        if params["for_offer"].presence
          @versions = @versions.offer_logs(params["item_id"]).join_users
        elsif params["for_item"].presence
          @versions = @versions.item_versions(params["item_id"]).union_all(@versions.package_versions(params["item_id"])).join_users
        else
          @versions = @versions.items_and_calls_log(User.current_user.id)
        end
        render_versions
      end

      api :GET, '/v1/versions/1', "List a version"
      def show
        render json: @version, serializer: serializer
      end

      private

      def serializer
        Api::V1::VersionSerializer
      end

      def render_versions
        data = ActiveModel::ArraySerializer.new(@versions, each_serializer: serializer, root: "versions").as_json
        render json: data
      end

    end
  end
end
