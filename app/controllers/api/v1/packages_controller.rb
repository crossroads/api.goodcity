module Api::V1
  class PackagesController < Api::V1::ApiController
    include GoodcitySync

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
        param :quantity, lambda { |val| [String, Fixnum].include? val.class }, desc: "Package quantity", allow_nil: true
        param :length, lambda { |val| [String, Fixnum].include? val.class }, desc: "Package length", allow_nil: true
        param :width, lambda { |val| [String, Fixnum].include? val.class }, desc: "Package width", allow_nil: true
        param :height, lambda { |val| [String, Fixnum].include? val.class }, desc: "Package height", allow_nil: true
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
      @package.inventory_number = remove_stockit_prefix(@package.inventory_number)
      if package_record
        @package.offer_id = offer_id
        if @package.save
          save_item_details
          render json: @package, serializer: serializer, status: 201
        else
          render json: {errors: @package.errors.full_messages}.to_json , status: 422
        end
      else
        render nothing: true, status: 204
      end
    end

    api :PUT, "/v1/packages/1", "Update a package"
    param_group :package
    def update
      @package.assign_attributes(package_params)
      # use valid? to ensure mark_received errors get caught
      if @package.valid? and @package.save
        render json: @package, serializer: serializer
      else
        render json: {errors: @package.errors.full_messages}.to_json , status: 422
      end
    end

    api :DELETE, "/v1/packages/1", "Delete an package"
    description "Deletion of the Package item in review mode"
    def destroy
      @package.really_destroy!
      render json: {}
    end

    api :POST, "/v1/packages/print_barcode", "Print barcode"
    def print_barcode
      begin
        package = Package.find params[:package_id]
      rescue ActiveRecord::RecordNotFound
        return render json: {errors:"Package not found with supplied package_id"}, status: 400
      end
      if package.inventory_number.blank?
        i = InventoryNumber.create
        package.inventory_number = i.id.to_s.rjust(6, "0")
        package.save
      end
      print_id, errors, status = barcode_service.print package.inventory_number
      render json: {
        status: status,
        errors: errors,
        inventory_number: package.inventory_number
      }, status: /pid \d+ exit 0/ =~ status.to_s ? 200 : 400
    end

    private

    def remove_stockit_prefix(stockit_inventory_number)
      stockit_inventory_number.gsub(/^x/i, '') unless stockit_inventory_number.blank?
    end

    def package_params
      attributes = [:quantity, :length, :width, :height, :notes, :item_id,
        :received_at, :rejected_at, :package_type_id, :state_event, :image_id,
        :inventory_number, :location_id, :designation_name]
      params.require(:package).permit(attributes)
    end

    def item_attributes
      if (item = item_params)
        item["donor_condition_id"] = DonorCondition.find_by(name_en: item["donor_condition_id"]).try(:id)
        item
      end
    end

    def item_params
      params["package"].require(:item).permit(:donor_condition_id)
    end

    def save_item_details
      params["package"]["item"] &&
      (attributes = item_attributes) &&
      @package.item.update_attributes(attributes)
    end

    def serializer
      Api::V1::PackageSerializer
    end

    def offer_id
      @package.item.offer_id
    end

    def package_record
      inventory_number = remove_stockit_prefix(@package.inventory_number)
      if inventory_number
        @package = Package.find_by(inventory_number: inventory_number)
        if @package
          GoodcitySync.request_from_stockit = true
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

    def barcode_service
      BarcodeService.new
    end
  end
end
