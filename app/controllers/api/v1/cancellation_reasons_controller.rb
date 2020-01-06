module Api
  module V1
    class CancellationReasonsController < Api::V1::ApiController
      load_and_authorize_resource :cancellation_reason, parent: false

      def index
        render json: cancellation_reasons, each_serializer: serializer
      end

      def show
        render json: @cancellation_reason, serializer: serializer
      end

      private

      def serializer
        Api::V1::CancellationReasonSerializer
      end

      def cancellation_reasons
        @cancellation_reasons.cancellation_reasons_by({
          ids: params["ids"],
          offer: params["offer"]
        })
      end
    end
  end
end
