module Api::V1
  class PackagesController < Api::V1::ApiController

    load_and_authorize_resource :package, parent: false

    resource_description do
      short 'List, create and show  package.'
      formats ['json']
      error 401, "Unauthorized"
      error 404, "Not Found"
      error 422, "Validation Error"
      error 500, "Internal Server Error"
    end

    def_param_group :package do
      param :package, Hash, required: true do
        param :quantity, Integer, desc: "Package quantity", allow_nil: true
        param :length, Integer, desc: "Package length", allow_nil: true
        param :width, Integer, desc: "Package width", allow_nil: true
        param :height, Integer, desc: "Package height", allow_nil: true
        param :notes, String, desc: "Comment mentioned by customer", allow_nil: true
        param :item_id, Integer, desc: "Item for which package is created", allow_nil: true
        param :state, String, desc: "State", allow_nil: true
        param :received_at, String, desc: "Date on which package is received", allow_nil: true
        param :rejected_at, String, desc: "Date on which package rejected", allow_nil: true
        param :package_type_id, String, desc: "Category of the package", allow_nil: true
      end
    end

    api :GET, '/v1/packages', "List all packages"
    def index
      @packages = @packages.find( params[:ids].split(",") ) if params[:ids].present?
      render json: @packages, each_serializer: serializer
    end

    api :GET, '/v1/packages/1', "Details of a package"
    def show
      render json: @package, serializer: serializer
    end

    api :POST, '/v1/packages', "Create a package"
    param_group :package
    def create
      @package = Package.new(package_params)
      if @package.save
        render json: @package, serializer: serializer, status: 201
      else
        render json: @package.errors.to_json, status: 422
      end
    end

    private
    def package_params
      attributes = [:quantity, :length, :width, :height, :notes, :item_id,
        :state, :received_at, :rejected_at, :package_type_id]
      params.require(:package).permit(attributes)
    end

    def serializer
      Api::V1::PackageSerializer
    end


  end
end
