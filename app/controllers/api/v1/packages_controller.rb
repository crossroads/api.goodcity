module Api
  module V1
    class PackagesController < Api::V1::ApiController
      include GoodcitySync

      load_and_authorize_resource :package, parent: false
      skip_before_action :validate_token, only: [:index, :show]

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
          param :quantity, lambda { |val| [String, Integer].include? val.class }, desc: "Package quantity", allow_nil: true
          param :received_quantity, lambda { |val| [String, Integer].include? val.class }, desc: "Package quantity", allow_nil: true
          param :length, lambda { |val| [String, Integer].include? val.class }, desc: "Package length", allow_nil: true
          param :width, lambda { |val| [String, Integer].include? val.class }, desc: "Package width", allow_nil: true
          param :height, lambda { |val| [String, Integer].include? val.class }, desc: "Package height", allow_nil: true
          param :notes, String, desc: "Comment mentioned by customer", allow_nil: true
          param :item_id, String, desc: "Item for which package is created", allow_nil: true
          param :state_event, Package.valid_events, allow_nil: true, desc: "Fires the state transition (if allowed) for this package."
          param :received_at, String, desc: "Date on which package is received", allow_nil: true
          param :rejected_at, String, desc: "Date on which package rejected", allow_nil: true
          param :package_type_id, lambda { |val| [String, Integer].include? val.class }, desc: "Category of the package", allow_nil: true
          param :favourite_image_id, lambda { |val| [String, Integer].include? val.class }, desc: "The id of the item image that represents this package", allow_nil: true
          param :donor_condition_id, lambda { |val| [String, Integer].include? val.class }, desc: "The id of donor-condition", allow_nil: true
          param :grade, String, allow_nil: true
        end
      end

      def_param_group :operations do
        param :quantity, [Integer, String], desc: "Package quantity", allow_nil: true
        param :order_id, [Integer, String], desc: "Order involved in the package's designation", allow_nil: true
        param :to, [Integer, String], desc: "Location the package is moved to", allow_nil: true
        param :from, [Integer, String], desc: "Location the package is moved from", allow_nil: true
      end

      api :POST, "/v1/packages", "Create a package"
      param_group :package

      def create
        package = package_service.new_package_object
        if package
          if package.valid? && package.save
            if is_stock_app?
              render json: package, serializer: stock_serializer, root: "item",
                     include_order: false, include_orders_packages: true
            else
              render json: package, serializer: serializer, status: 201
            end
          else
            render json: { errors: package.errors.full_messages }, status: 422
          end
        else
          render nothing: true, status: 204
        end
      end

      api :DELETE, "/v1/packages/1", "Delete an package"
      description "Deletion of the Package item in review mode"

      def destroy
        @package.really_destroy!
        render json: {}
      end

      api :PUT, "/v1/packages/1/designate", "Designate a package's quantity to an order"
      param_group :operations
      def designate
        quantity = params[:quantity].to_i
        order_id = params[:order_id]

        Package::Operations.designate(@package, quantity: quantity, to_order: order_id)
        send_stock_item_response
      end

      api :GET, "/v1/packages", "get all packages for the item"

      def index
        @packages = @packages.browse_public_packages if is_browse_app?
        @packages = @packages.find(params[:ids].split(",")) if params[:ids].present?
        @packages = @packages.search({ search_text: params["searchText"] })
          .page(page).per(per_page) if params["searchText"]
        render json: @packages, each_serializer: serializer, include_orders_packages: is_stock_app?, is_browse_app: is_browse_app?
      end

      api :PUT, "/v1/packages/1/move", "Move a package's quantity to an new location"
      param_group :operations
      def move
        quantity = params[:quantity].to_i
        Package::Operations.move(quantity, @package, from: params[:from], to: params[:to])
        send_stock_item_response
      end

      api :POST, "/v1/packages/print_barcode", "Print barcode"

      def print_barcode
        return render json: { errors: I18n.t("package.max_print_error", max_barcode_qty: MAX_BARCODE_PRINT) }, status: 400 unless print_count.between?(1, MAX_BARCODE_PRINT)
        begin
          @package = Package.find params[:package_id]
        rescue ActiveRecord::RecordNotFound
          return render json: { errors: "Package not found with supplied package_id" }, status: 400
        end
        if @package.inventory_number.blank?
          @package.inventory_number = InventoryNumber.next_code
          @package.save
        end
        print_inventory_label
      end

      # print inventory label
      def print_inventory_label
        PrintLabelJob.perform_later(@package.id, User.current_user.id, "inventory_label", print_count)
        render json: {}, status: 204
      end

      def remove_from_set
        @package.remove_from_set
        render json: @package, serializer: stock_serializer, root: "item",
          include_order: false
      end

      def send_stock_item_response
        @package.reload
        if @package.errors.blank? && @package.valid? && @package.save
          render json: stock_serializer.new(@package,
            root: "item",
            include_order: true,
            include_packages: false,
            include_allowed_actions: true,
            include_images: @package.set_item_id.blank?
          )
        else
          render json: { errors: @package.errors.full_messages }, status: 422
        end
      end

      api :GET, "/v1/packages/search_stockit_items", "Search packages (items for stock app) using inventory-number"

      def search_stockit_items
        records = @packages # security
        if params["searchText"].present?
          records = records.search(
            search_text: params["searchText"],
            item_id: params["itemId"],
            restrict_multi_quantity: params["restrictMultiQuantity"],
            with_inventory_no: params["withInventoryNumber"] == "true"
          )
        end
        params_for_filter = %w[state location].each_with_object({}) { |k, h| h[k] = params[k] if params[k].present? }
        records = records.filter(params_for_filter)
        records = records.order("packages.id desc").page(params["page"]).per(params["per_page"] || DEFAULT_SEARCH_COUNT)
        packages = ActiveModel::ArraySerializer.new(records,
                                                    each_serializer: stock_serializer,
                                                    root: "items",
                                                    include_order: false,
                                                    include_packages: false,
                                                    include_orders_packages: true,
                                                    exclude_stockit_set_item: true,
                                                    include_images: true).as_json
        render json: { meta: { total_pages: records.total_pages, search: params["searchText"] } }.merge(packages)
      end

      api :GET, "/v1/packages/1", "Details of a package"

      def show
        render json: serializer.new(@package, include_orders_packages: true).as_json
      end

      def split_package
        qty_to_split = package_params[:quantity].to_i
        package_splitter = PackageSplitter.new(@package, qty_to_split)
        if package_splitter.splittable?
          package_splitter.split!
          send_stock_item_response
        else
          render json: { errors: I18n.t("package.split_qty_error", qty: @package.quantity) }, status: 422
        end
      end

      api :GET, "/v1/stockit_items/1", "Details of a stockit_item(package)"

      def stockit_item_details
        render json: stock_serializer.new(@package,
          serializer: stock_serializer,
          root: "item",
          include_order: true,
          include_orders_packages: true,
          exclude_stockit_set_item: @package.set_item_id.blank?,
          include_images: @package.set_item_id.blank?,
          include_allowed_actions: true).as_json
      end

      api :PUT, "/v1/packages/1", "Update a package"
      param_group :package

      def update
        package = package_service.updated_package_object
        # use valid? to ensure mark_received errors get caught
        if package.valid? and package.save
          if is_stock_app?
            stockit_item_details
          else
            render json: package, serializer: serializer, include_orders_packages: true
          end
        else
          render json: { errors: package.errors.full_messages }, status: 422
        end
      end

      private

      def serializer
        Api::V1::PackageSerializer
      end

      def stock_serializer
        Api::V1::StockitItemSerializer
      end

      def package_service
        PackageService.new(@package, params, app_name, package_params)
      end

      def set_favourite_image
        if (image_id = params["package"]["favourite_image_id"]).present?
          if package.images.pluck(:id).include?(image_id)
            @package.update_favourite_image(image_id)
          end
          params["package"].delete("favourite_image_id")
        end
      end

      def add_favourite_image
        image = Image.find_by(id: params["package"]["favourite_image_id"])
        @package.images.build(favourite: true, angle: image.angle,
                              cloudinary_id: image.cloudinary_id) if image
        params["package"].delete("favourite_image_id")
      end

      def get_package_type_id_value
        code_id = params["package"]["code_id"]
        if params["package"]["package_type_id"].blank? and code_id.present?
          params["package"]["package_type_id"] = PackageType.find_by(stockit_id: code_id).try(:id)
          params["package"].delete("code_id")
        end
      end

      def package_params
        get_package_type_id_value
        set_favourite_image if @package && !@package.new_record?
        attributes = [
          :allow_web_publish, :box_id, :case_number, :designation_name,
          :detail_id, :detail_type, :donor_condition_id, :grade, :height,
          :inventory_number, :item_id, :length, :location_id, :notes, :order_id,
          :package_type_id, :pallet_id, :pieces, :quantity, :received_at,
          :received_quantity, :rejected_at, :state, :state_event, :stockit_designated_on,
          :stockit_id, :stockit_sent_on, :weight, :width,
          packages_locations_attributes: %i[id location_id quantity],
          detail_attributes: [:id, computer_attributes, electrical_attributes,
                              computer_accessory_attributes].flatten.uniq
        ]

        params.require(:package).permit(attributes)
      end

      # comp_test_status, frequency, test_status, voltage kept for stockit sync
      # will be removed later once we get rid of stockit
      def computer_attributes
        %i[
          brand comp_test_status comp_test_status_id comp_voltage country_id cpu
          hdd lan mar_ms_office_serial_num mar_os_serial_num model
          ms_office_serial_num optical os os_serial_num ram serial_num size
          sound updated_by_id usb video wireless
        ]
      end

      def electrical_attributes
        %i[
          brand country_id frequency frequency_id model power serial_number standard
          system_or_region test_status test_status_id tested_on updated_by_id
          voltage voltage_id
        ]
      end

      def computer_accessory_attributes
        %i[
          brand comp_test_status comp_test_status_id comp_voltage country_id
          interface model serial_num size updated_by_id
        ]
      end
    end
  end
end
