module Api::V1
  class DistrictsController < Api::V1::ApiController

    load_and_authorize_resource :district, parent: false

    def index
      if params[:ids].blank?
        render json: District.cached_json
        return
      end
      @districts = @districts.find( params[:ids].split(",") ) if params[:ids].present?
      render json: @districts, each_serializer: serializer
    end

    def show
      render json: @district, serializer: serializer
    end

    private

    def serializer
      Api::V1::DistrictSerializer
    end

  end
end
