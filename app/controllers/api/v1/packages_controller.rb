module Api::V1
  class PackagesController < Api::V1::ApiController

    load_and_authorize_resource :package, parent: false

    def index
      @packages = @packages.find( params[:ids].split(",") ) if params[:ids].present?
      render json: @packages, each_serializer: serializer
    end

    def show
      render json: @package, serializer: serializer
    end

    private

    def serializer
      Api::V1::PackageSerializer
    end

  end
end
