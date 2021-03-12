# frozen_string_literal: true

module Api
  module V1
    # Api::V1::CannedResponseController
    class CannedResponsesController < Api::V1::ApiController
      load_and_authorize_resource :canned_response, parent: false, except: :show
      skip_authorization_check only: :show

      def index
        is_private = bool_cast(params['isPrivate']) || false
        @canned_responses = @canned_responses.by_private(is_private)
        return search_and_render_canned_message if params['searchText'].present?

        render json: @canned_responses, each_serializer: serializer
      end

      def create
        save_and_render_object_with_errors(@canned_response)
      end

      def update
        @canned_response.assign_attributes(canned_response_params)
        update_and_render_object_with_errors(@canned_response)
      end

      def destroy
        @canned_response.destroy
        render json: {}
      end

      api :show, '/v1/canned_responses/:guid', 'Get canned response identified by guid'
      def show
        record = strict_find(params[:guid])
        render json: serializer.new(record).as_json
      end

      private

      def canned_response_params
        params.require(:canned_response).permit(:name_en, :name_zh_tw, :content_en, :content_zh_tw)
      end

      def search_and_render_canned_message
        result = @canned_responses.search(params['searchText'])
        render json: result, each_serializer: serializer
      end

      def strict_find(guid)
        record = CannedResponse.find_by(guid: guid)

        raise Goodcity::NotFoundError if record.nil?

        record
      end

      def serializer
        Api::V1::CannedResponseSerializer
      end
    end
  end
end
