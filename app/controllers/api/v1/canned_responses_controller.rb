# frozen_string_literal: true

module Api
  module V1
    # Api::V1::CannedResponseController
    class CannedResponsesController < Api::V1::ApiController
      load_and_authorize_resource :canned_response, parent: false, except: :show
      skip_authorization_check only: :show

      def_param_group :canned_response do
        param :canned_response, Hash, required: true do
          param :name_en, String, desc: 'English name for the canned_response', required: true
          param :name_zh_tw, String, desc: 'Chinese name for the canned_response', required: false, allow_nil: true
          param :content_en, String, desc: 'English content for the canned_response', required: true
          param :content_zh_tw, String, desc: 'Chinese content for the canned_response', required: false, allow_nil: true
        end
      end

      api :GET, '/v1/canned_responses', 'List all private / non private canned_responses'
      param :isPrivate, String, desc: 'Flag to indicate private / non private message'
      def index
        is_private = bool_param(:isPrivate)
        @canned_responses = @canned_responses.by_private(is_private)
        return search_and_render_canned_message if params['searchText'].present?

        render json: @canned_responses, each_serializer: serializer
      end

      api :POST, '/v1/canned_responses', 'Creates new non-private canned_responses'
      param_group :canned_response
      def create
        save_and_render_object_with_errors(@canned_response)
      end

      api :PUT, '/v1/canned_responses/:id', 'Updates canned_responses for the id'
      def update
        @canned_response.assign_attributes(canned_response_params)
        update_and_render_object_with_errors(@canned_response)
      end

      api :DELETE, '/v1/canned_responses/:id', 'Delete canned_responses by id'
      param :id, String, desc: 'ID of the canned_response to be deleted'
      def destroy
        @canned_response.destroy
        render json: {}
      end

      api :SHOW, '/v1/canned_responses/:guid', 'Get canned_response identified by guid'
      description <<-DESCRIPTION
      A list of GUID's for the messages \n.
      logistics-complete-review-message: Message to load when offer is reviewed and transportation needs to be arranged.
      review-offer-close-offer-message: Message to load when offer is rejected.
      review-offer-missing-offer-message: Message to load when delivery is done but the items are missing.
      review-offer-receive-offer-message: Message to load when all items of offers are recieved successfully.
      DESCRIPTION
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
