module Api::V1
  class TerritoriesController < Api::V1::ApiController
    skip_before_action :validate_token, only: [:index]
    load_and_authorize_resource :territory, parent: false

    def index
      @territories = @territories.with_eager_load # this maintains security
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
