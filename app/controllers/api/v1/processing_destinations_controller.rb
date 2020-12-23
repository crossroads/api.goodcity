# frozen_string_literal: true

module Api
  module V1
    class ProcessingDestinationsController < Api::V1::ApiController
      load_and_authorize_resource :processing_destination, parent: false

      resource_description do
        short 'List Processing Destination Items'
        formats ['json']
        error 401, 'Unauthorized'
        error 404, 'Not Found'
        error 422, 'Validation Error'
        error 500, 'Internal Server Error'
      end

      api :GET, '/v1/processing_destinations', 'List all Processing Destination Lookups.'

      def index
        render json: @processing_destinations, each_serializer: serializer
      end

      private

      def serializer
        Api::V1::ProcessingDestinationSerializer
      end
    end
  end
end
