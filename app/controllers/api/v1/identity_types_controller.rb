module Api
  module V1
    class IdentityTypesController < Api::V1::ApiController
      skip_before_action :validate_token, only: [:index, :show]
      load_and_authorize_resource :identity_type, parent: false

      resource_description do
        short 'Identity types are the different kind of travel documents a user can have (hkid, asrf, ...)'
        formats ['json']
        error 401, "Unauthorized"
        error 404, "Not Found"
        error 422, "Validation Error"
        error 500, "Internal Server Error"
      end

      def_param_group :identity_type do
        param :identity_type, Hash, required: true do
          param :name, String, desc: "Name of the Identity type"
        end
      end

      api :GET, '/v1/identity_types', "List all identity types"
      def index
        render_objects_with_cache(@identity_types, [])
      end

      api :GET, '/v1/identity_type/1', "Get a single identity type"
      def show
        render json: @identity_type, serializer: serializer
      end

      private

      def serializer
        Api::V1::IdentityTypeSerializer
      end
    end
  end
end
