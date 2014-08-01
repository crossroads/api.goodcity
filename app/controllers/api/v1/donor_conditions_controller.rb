module Api::V1
  class DonorConditionsController < Api::V1::ApiController

    load_and_authorize_resource :donor_condition, parent: false

    def index
      @donor_conditions = @donor_conditions.find( params[:ids].split(",") ) if params[:ids].present?
      render json: @donor_conditions, each_serializer: serializer
    end

    def show
      render json: @donor_condition, serializer: serializer
    end

    private

    def serializer
      Api::V1::DonorConditionSerializer
    end

  end
end
