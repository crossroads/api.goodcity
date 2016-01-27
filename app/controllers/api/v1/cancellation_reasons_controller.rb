module Api::V1
  class CancellationReasonsController < Api::V1::ApiController

    load_and_authorize_resource :cancellation_reason, parent: false

    def index
      if params[:ids].blank?
        render json: CancellationReason.visible.cached_json
        return
      end
      @cancellation_reasons = @cancellation_reasons.find( params[:ids].split(",") ) if params[:ids].present?
      render json: @cancellation_reasons, each_serializer: serializer
    end

    def show
      render json: @cancellation_reason, serializer: serializer
    end

    private

    def serializer
      Api::V1::CancellationReasonSerializer
    end

  end
end
