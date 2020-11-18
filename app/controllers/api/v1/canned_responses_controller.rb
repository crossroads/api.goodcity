# frozen_string_literal: true

module Api
  module V1
    # Api::V1::CannedResponseController
    class CannedResponsesController < Api::V1::ApiController
      load_and_authorize_resource :canned_response, parent: false

      def index
        return search_and_render_canned_message if params['searchText'].present?

        render json: CannedResponse.cached_json, each_serializer: serializer
      end

      private

      def search_and_render_canned_message
        result = @canned_responses.search(params['searchText'])
        render json: result, each_serializer: serializer
      end

      def serializer
        Api::V1::CannedResponseSerializer
      end
    end
  end
end
