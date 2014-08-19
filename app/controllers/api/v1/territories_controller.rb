module Api::V1
  class TerritoriesController < Api::V1::ApiController

    skip_before_action :validate_token, only: [:index, :show]
    load_and_authorize_resource :territory, parent: false

    def index
      if params[:ids].blank?
        districts = District.cached_json
        territories = Territory.cached_json
        render json:{districts: districts, territories: territories}
        return
      end
      @territories = @territories.with_eager_load
      @territories = @territories.find( params[:ids].split(",") ) if params[:ids].present?
      render json: @territories, each_serializer: serializer
    end

    def show
      render json: @territory, serializer: serializer
    end

    private

    def serializer
      Api::V1::TerritorySerializer
    end

  end
end
