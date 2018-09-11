module Api
  module V1
    class RejectionReasonsController < Api::V1::ApiController
      load_and_authorize_resource :rejection_reason, parent: false

      api :GET, '/v1/rejections_reasons', "List all rejection reasons."
      def index
        render_objects_with_cache(@rejection_reasons, params[:ids])
      end

      api :GET, '/v1/rejection_reasons/1', "List a Rejection Reason"
      def show
        render json: @rejection_reason, serializer: serializer
      end

      private

      def serializer
        Api::V1::RejectionReasonSerializer
      end
    end
  end
end
