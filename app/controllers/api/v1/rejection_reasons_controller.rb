module Api::V1
  class RejectionReasonsController < Api::V1::ApiController

    load_and_authorize_resource :rejection_reason, parent: false

    def index
      if params[:ids].present?
        @rejection_reasons = @rejection_reasons.find( params[:ids].split(",") )
      end
      render json: @rejection_reasons, each_serializer: serializer
    end

    def show
      render json: @rejection_reason, serializer: serializer
    end

    private

    def serializer
      Api::V1::RejectionReasonSerializer
    end

  end
end
