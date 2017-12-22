module Api
  module V1
    class VersionsController < Api::V1::ApiController
      load_and_authorize_resource :version, parent: false

      resource_description do
        short 'List Versions of items and related packages'
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      api :GET, '/v1/Versions', "List Versions of items and related packages"
      def index
        return offer_logs if params["for_offer"].presence
        return item_logs if params["for_item"].presence
        render json: @versions.items_and_calls_log
      end

      api :GET, '/v1/versions/1', "List a version"
      def show
        render json: @version, serializer: serializer
      end

      def offer_logs
        render json: @versions.offer_logs(params["item_id"]).join_users, each_serializer: serializer
      end

      def item_logs
        versions = @versions.item_versions(params["item_id"]).union_all(
          @versions.package_versions(params["item_id"]))
        render json: versions.join_users, each_serializer: serializer
      end

      private

      def serializer
        Api::V1::VersionSerializer
      end
    end
  end
end
