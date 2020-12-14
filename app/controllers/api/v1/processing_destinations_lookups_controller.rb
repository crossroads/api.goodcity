# frozen_string_literal: true

module Api
  module V1
    class ProcessingDestinationsLookupsController < Api::V1::ApiController
      load_and_authorize_resource :processing_destinations_lookup, parent: false

      resource_description do
        short 'List Processing Destination Items'
        formats ['json']
        error 401, 'Unauthorized'
        error 404, 'Not Found'
        error 422, 'Validation Error'
        error 500, 'Internal Server Error'
      end

      api :GET, '/v1/processing_destinations_lookups', 'List all Processing Destination Lookups.'

      def index
        render json: @processing_destinations_lookups, each_serializer: serializer
      end

      private

      def serializer
        Api::V1::ProcessingDestinationsLookupSerializer
      end
    end
  end
end
