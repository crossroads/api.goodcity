module Api::V1
  class PackagesController < Api::V1::ApiController

    skip_before_action :validate_token, only: :create
    load_and_authorize_resource :package, parent: false

    resource_description do
      short "Create, update and delete a package."
      formats ["json"]
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
        param :item_id, String, desc: "Item for which package is created", allow_nil: true
        param :state_event, Package.valid_events, allow_nil: true, desc: "Fires the state transition (if allowed) for this package."
        param :received_at, String, desc: "Date on which package is received", allow_nil: true
        param :rejected_at, String, desc: "Date on which package rejected", allow_nil: true
        param :package_type_id, String, desc: "Category of the package", allow_nil: true
        param :image_id, Integer, desc: "The id of the item image that represents this package", allow_nil: true
      end
    end

    api :GET, "/v1/packages", "get all packages for the item"
    def index
      @packages = @packages.find( params[:ids].split(",") ) if params[:ids].present?
      render json: @packages, each_serializer: serializer
    end

    api :GET, '/v1/packages/1', "Details of a package"
    def show
      render json: @package, serializer: serializer
    end

    api :POST, "/v1/packages", "Create a package"
    param_group :package
    def create
      if package_record
        @package.offer_id = offer_id
        if @package.save
          render json: @package, serializer: serializer, status: 201
        else
          render json: @package.errors.to_json, status: 422
        end
      else
        render nothing: true, status: 204
      end
    end

    api :PUT, "/v1/packages/1", "Update a package"
    param_group :package
    def update
      @package.assign_attributes(package_params)
      response = add_item_to_stockit
      if response && (response["errors"] || response[:errors])
        render json: response.to_json, status: 422
      else
        if @package.save
          render json: @package, serializer: serializer
        else
          render json: @package.errors.to_json, status: 422
        end
      end
    end

    api :DELETE, "/v1/packages/1", "Delete an package"
    description "Deletion of the Package item in review mode"
    def destroy
      @package.really_destroy!
      render json: {}
    end

    private

    def add_item_to_stockit
      case params["package"]["state_event"]
      when "mark_received"
        Stockit::Browse.new(@package).add_item
      when "mark_missing"
        Stockit::Browse.new(@package.inventory_number).remove_item
      end
    end

    def package_params
      attributes = [:quantity, :length, :width, :height, :notes, :item_id,
        :received_at, :rejected_at, :package_type_id, :state_event, :image_id,
        :inventory_number, :location_id, :designation_name]
      params.require(:package).permit(attributes)
    end

    def serializer
      Api::V1::PackageSerializer
    end

    def offer_id
      Item.where(id: @package.item_id).pluck(:offer_id).first
    end

    def package_record
      if package_params[:inventory_number]
        if existing_package
          @package.assign_attributes(package_params)
          @package.location_id = location_id
          @package
        end
      else
        @package = Package.new(package_params)
      end
    end

    def location_id
      Location.find_by(stockit_id: package_params[:location_id]).try(:id)
    end

    def existing_package
      @package = Package.find_by(inventory_number: package_params[:inventory_number])
    end

  end
end
