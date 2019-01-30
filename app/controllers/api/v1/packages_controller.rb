module Api
  module V1
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

      api :GET, "/v1/packages", "get all packages for the item"
      def index
        @packages = @packages.find(params[:ids].split(",")) if params[:ids].present?
        render json: @packages, each_serializer: serializer, include_orders_packages: true
      end

      api :GET, '/v1/packages/1', "Details of a package"
      def show
        render json: @package, serializer: serializer, include_orders_packages: true
      end

      api :GET, '/v1/stockit_items/1', "Details of a stockit_item(package)"
      def stockit_item_details
        render json: @package,
          serializer: stock_serializer,
          root: "item",
          include_order: true,
          include_orders_packages: true,
          exclude_stockit_set_item: @package.set_item_id.blank? ? true : false,
          include_images: @package.set_item_id.blank?,
          include_stock_condition: is_stock_app?
      end

      api :POST, "/v1/packages", "Create a package"
      param_group :package
      def create
        @package.inventory_number = remove_stockit_prefix(@package.inventory_number)
        if package_record
          @package.offer_id = offer_id
          if @package.valid? && @package.save
            if is_stock_app?
              render json: @package, serializer: stock_serializer, root: "item",
            include_order: false, include_orders_packages: true
            else
              render json: @package, serializer: serializer, status: 201
            end
          else
            render json: { errors: @package.errors.full_messages }, status: 422
          end
        else
          render nothing: true, status: 204
        end
      end

      api :PUT, "/v1/packages/1", "Update a package"
      param_group :package
      def update
        @package.assign_attributes(package_params)
        @package.received_quantity = package_params[:quantity] if package_params[:quantity]
        @package.donor_condition_id = package_params[:donor_condition_id] if assign_donor_condition?
        @package.request_from_admin = is_admin_app?
        packages_location_for_admin

        # use valid? to ensure mark_received errors get caught
        if @package.valid? and @package.save
          if is_stock_app?
            stockit_item_details
          else
            render json: @package, serializer: serializer, include_orders_packages: true
          end
        else
          render json: { errors: @package.errors.full_messages } , status: 422
        end
      end

      def assign_donor_condition?
        package_params[:donor_condition_id] && is_stock_app?
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
          @package = Package.find params[:package_id]
        rescue ActiveRecord::RecordNotFound
          return render json: { errors:"Package not found with supplied package_id" }, status: 400
        end
        if @package.inventory_number.blank?
          @package.inventory_number = InventoryNumber.next_code
          @package.save
        end
        print_inventory_label
      end

      api :GET, "/v1/packages/search_stockit_items", "Search packages (items for stock app) using inventory-number"
      def search_stockit_items
        records = {}; pages = 0
        if params['searchText'].present?
          records = params["orderId"].present? ? @packages.undispatched : @packages
          records = records.search(
            params['searchText'],
            params['itemId'].presence,
            with_inventory_no: params['withInventoryNumber'] == 'true'
          )
          # apply selected filters
          records = apply_filters(records).page(params["page"]).per(params["per_page"])
          pages = records.total_pages
        end
        packages = ActiveModel::ArraySerializer.new(records,
          each_serializer: stock_serializer,
          root: "items",
          include_order: true,
          include_packages: false,
          include_orders_packages: true,
          exclude_stockit_set_item: true,
          include_images: true,
          include_stock_condition: is_stock_app?).as_json
        render json: {meta: { total_pages: pages, search: params['searchText'] } }.merge(packages)
      end

      def designate_stockit_item(order_id)
        @package.designate_to_stockit_order(order_id)
      end

      def undesignate_partial_item
        OrdersPackage.undesignate_partially_designated_item(params[:package])
        @package.undesignate_from_stockit_order
        send_stock_item_response
      end

      def designate_partial_item
        result = OrdersPackage.add_partially_designated_item(
          order_id: params[:package][:order_id],
          package_id: params[:package][:package_id],
          quantity: params[:package][:quantity])
        if result.errors.blank?
          designate_stockit_item(params[:package][:order_id])
          send_stock_item_response
        else
          render json: { errors: result.errors.full_messages }, status: 422
        end
      end

      def split_package
        qty_to_split = package_params[:quantity].to_i
        package_splitter = PackageSplitter.new(@package, qty_to_split)
        if package_splitter.splittable?
          package_splitter.split!
          send_stock_item_response
        else
          render json: { errors: I18n.t('package.split_qty_error', qty: @package.quantity) }, status: 422
        end
      end

      def update_partial_quantity_of_same_designation
        @orders_package = OrdersPackage.find_by(id: params[:package][:orders_package_id])
        @orders_package.update_partially_designated_item(params[:package])
        designate_stockit_item(params[:package][:order_id])
        send_stock_item_response
      end

      def undesignate_stockit_item
        @package.undesignate_from_stockit_order
        send_stock_item_response
      end

      def dispatch_stockit_item
        @orders_package = OrdersPackage.find_by(id: params[:package][:order_package_id])
        if @orders_package.dispatch_orders_package
          @package.dispatch_stockit_item(@orders_package, params["packages_location_and_qty"], true)
          send_stock_item_response
        else
          render json: { errors: I18n.t('orders_package.already_dispatched') } , status: 422
        end
      end

      def undispatch_stockit_item
        @package.undispatch_stockit_item
        send_stock_item_response
      end

      def move_partial_quantity
        package_params = JSON.parse(params["package"])
        @package.move_partial_quantity(params["location_id"], package_params, params["total_qty"])
        send_stock_item_response
      end

      def move_full_quantity
        orders_package = OrdersPackage.find_by(id: params["ordersPackageId"])
        orders_package.undispatch_orders_package
        @package.move_full_quantity(params["location_id"], params["ordersPackageId"])
        @package.undispatch_stockit_item
        send_stock_item_response
      end

      def move_stockit_item
        @package.move_stockit_item(params["location_id"])
        send_stock_item_response
      end

      def remove_from_set
        @package.remove_from_set
        render json: @package, serializer: stock_serializer, root: "item",
          include_order: false
      end

      def send_stock_item_response
        if @package.errors.blank? && @package.valid? && @package.save
          render json: @package,
            serializer: stock_serializer,
            root: "item",
            include_order: true,
            include_packages: false,
            include_images: @package.set_item_id.blank?
        else
          render json: { errors: @package.errors.full_messages } , status: 422
        end
      end

      def print_inventory_label
        _print_id, errors, status = barcode_service.print @package.inventory_number
        render json: {
          status: status,
          errors: errors,
          inventory_number: @package.inventory_number
        }, status: /pid \d+ exit 0/ =~ status.to_s ? 200 : 400
      end

      private

      def array_param(key)
        params.fetch(key, "").strip.split(',')
      end

      def apply_filters(records)
        records.filter(
          states: array_param(:state),
          location: params[:location]
        )
      end

      def stock_serializer
        Api::V1::StockitItemSerializer
      end

      def remove_stockit_prefix(stockit_inventory_number)
        stockit_inventory_number.gsub(/^x/i, '') unless stockit_inventory_number.blank?
      end

      def package_params
        get_package_type_id_value
        set_favourite_image if @package && !@package.new_record?
        attributes = [:quantity, :length, :width, :height, :notes, :item_id,
          :received_at, :rejected_at, :package_type_id, :state_event,
          :inventory_number, :designation_name, :donor_condition_id, :grade,
          :location_id, :box_id, :pallet_id, :stockit_id,
          :order_id, :stockit_designated_on, :stockit_sent_on,
          :case_number, :allow_web_publish, :received_quantity, :state,
          packages_locations_attributes: [:id, :location_id, :quantity]]
        params.require(:package).permit(attributes)
      end

      def set_favourite_image
        if(image_id = params["package"]["favourite_image_id"]).present?
          if @package.images.pluck(:id).include?(image_id)
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

      def serializer
        Api::V1::PackageSerializer
      end

      def offer_id
        @package.try(:item).try(:offer_id)
      end

      def package_record
        if is_stock_app?
          @package.donor_condition_id = package_params[:donor_condition_id] if assign_donor_condition?
          @package.inventory_number = inventory_number
          @package
        elsif inventory_number
          assign_values_to_existing_or_new_package
        else
          @package.assign_attributes(package_params)
        end
        @package.received_quantity ||= received_quantity
        add_favourite_image if params["package"]["favourite_image_id"]
        @package
      end

      def assign_values_to_existing_or_new_package
        new_package_params = package_params
        GoodcitySync.request_from_stockit = true
        @package = existing_package || Package.new()
        delete_params_quantity_if_all_quantity_designated(new_package_params)
        @package.assign_attributes(new_package_params)
        @package.received_quantity = received_quantity
        @package.build_or_create_packages_location(location_id, 'build')
        @package.location_id = location_id
        @package.state = 'received'
        @package.order_id = order_id
        @package.inventory_number = inventory_number
        @package.box_id = box_id
        @package.pallet_id = pallet_id
        @package
      end

      def packages_location_for_admin
        if is_admin_app? && params[:package][:location_id].present?
          @package.build_or_create_packages_location(params[:package][:location_id], 'create')
        end
      end

      def received_quantity
        params[:package][:quantity].to_i
      end

      def location_id
        if package_params[:location_id]
          Location.find_by(stockit_id: package_params[:location_id]).try(:id)
        end
      end

      def box_id
        Box.find_by(stockit_id: package_params[:box_id]).try(:id)
      end

      def pallet_id
        Pallet.find_by(stockit_id: package_params[:pallet_id]).try(:id)
      end

      def order_id
        if(package_params[:order_id])
          Order.accessible_by(current_ability).find_by(stockit_id: package_params[:order_id]).try(:id)
        end
      end

      def barcode_service
        BarcodeService.new
      end

      def existing_package
        if (stockit_id = package_params[:stockit_id])
          Package.find_by(stockit_id: stockit_id)
        end
      end

      def inventory_number
        remove_stockit_prefix(@package.inventory_number)
      end

      def delete_params_quantity_if_all_quantity_designated(new_package_params)
        if new_package_params['quantity'].to_i == @package.total_assigned_quantity
          new_package_params.delete('quantity')
        end
      end
    end
  end
end
