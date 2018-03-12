module Api
  module V1
    class RolesController < Api::V1::ApiController
      load_and_authorize_resource :role, parent: false

      def index
        render json: Role.visible.cached_json
      end

      def show
        render json: @role, serializer: serializer
      end

      private

      def serializer
        Api::V1::RoleSerializer
      end
    end
  end
end
