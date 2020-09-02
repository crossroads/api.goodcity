# frozen_string_literal: true

# organisation_types_controller
module Api
  module V1
    class OrganisationTypesController < Api::V1::ApiController
      load_and_authorize_resource :organisation_type, parent: false

      def index
        render json: @organisation_types, each_serializer: serializer
      end

      private

      def serializer
        Api::V1::OrganisationTypesSerializer
      end
    end
  end
end
