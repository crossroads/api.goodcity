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
        param :description, [Integer, String], desc: "Location the package is moved from", allow_nil: true
      end

      api :GET, "/v1/packages", "get all packages for the item"

      def index
        @packages = @packages.browse_public_packages if is_browse_app?
        @packages = @packages.find(params[:ids].split(",")) if params[:ids].present?
        @packages = @packages.search({ search_text: params["searchText"] })
          .page(page).per(per_page) if params["searchText"]
        render json: @packages, each_serializer: serializer,
          include_orders_packages: is_stock_app?,
          is_browse_app: is_browse_app?,
          include_package_set: bool_param(:include_package_set, false)
      end

      api :GET, "/v1/packages/1", "Details of a package"

      def show
        render json: serializer.new(@package, include_orders_packages: true).as_json
      end

      api :GET, "/v1/stockit_items/1", "Details of a stockit_item(package)"

      def stockit_item_details
        render json: stock_serializer
          .new(@package,
               serializer: stock_serializer,
               root: 'item',
               include_order: true,
               include_orders_packages: true,
               include_package_set: true,
               include_images: true,
               include_allowed_actions: true).as_json
      end

      api :POST, "/v1/packages", "Create a package"
      param_group :package

      def create
        # Callers
        # - Goodcity for create
        # - StockIt for create+update+designate+dispatch
        @package.inventory_number = remove_stockit_prefix(@package.inventory_number)

        success = ActiveRecord::Base.transaction do
          initialize_package_record
          dispatch_from_stockit = is_stockit_request? && (@package.stockit_sent_on_changed? || @package.order_id_changed?)
          quantity_changed = @package.received_quantity_changed?
          quantity_was = @package.received_quantity_was || 0
          if @package.valid? && @package.save
            try_inventorize_package(@package) if @package.inventory_number.present?
            if is_stockit_request?
              apply_stockit_quantity_change(@package, previous: quantity_was, current: @package.received_quantity) if quantity_changed && quantity_was > 0
              apply_stockit_dispatch(@package) if dispatch_from_stockit
              apply_stockit_move(@package) unless location_id == @package.locations.first.try(:id)
            end
            true
          else
            false
          end
        end

        if success
          # @TODO: unify package under a single serializer
          if is_stock_app?
            render json: @package, serializer: stock_serializer, root: "item",
                    include_order: false, include_orders_packages: true
          else
            render json: @package, serializer: serializer, status: 201
          end
        else
          render json: { errors: @package.errors.full_messages }, status: 422
        end
      end

      api :PUT, "/v1/packages/1", "Update a package"
      param_group :package

      def update
        @package.detail = assign_detail if params["package"]["detail_type"].present?
        @package.assign_attributes(package_params)
        @package.received_quantity = package_params[:quantity] if package_params[:quantity].to_i.positive?
        @package.donor_condition_id = package_params[:donor_condition_id] if assign_donor_condition?
        @package.request_from_admin = is_admin_app?

        success = ActiveRecord::Base.transaction do
          if @package.valid? && @package.save
            try_inventorize_package(@package) if location_id.present? && @package.inventory_number.present?
            true
          else
            false
          end
        end

        if success
          if is_stock_app?
            stockit_item_details
          else
            render json: @package, serializer: serializer, include_orders_packages: true
          end
        else
          render json: { errors: @package.errors.full_messages }, status: 422
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
      rescue ActiveRecord::InvalidForeignKey
        raise Goodcity::InventorizedPackageError
      end

      api :PUT, "/v1/packages/1", "Mark a package as missing"
      def mark_missing
        ActiveRecord::Base.transaction do
          Package::Operations.uninventorize(@package) if PackagesInventory.inventorized?(@package)
          @package.mark_missing
        end
        render json: serializer.new(@package).as_json
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

      api :GET, '/v1/packages/package_valuation',
          'Get valuation of package based on its
           condition, grade and package type'
      param :donor_condition_id, [Integer, String], :required => true
      param :grade, String, :required => true
      param :package_type_id, [Integer, String], :required => true

      def package_valuation
        valuation = ValuationCalculationHelper.new(params['donor_condition_id'],
                                                   params['grade'],
                                                   params['package_type_id'])
                                              .calculate
        render json: { value_hk_dollar: valuation }, status: 200
      end

      def print_inventory_label
        PrintLabelJob.perform_later(@package.id, User.current_user.id, "inventory_label", print_count)
        render json: {}, status: 204
      end

      api :GET, "/v1/packages/search_stockit_items", "Search packages (items for stock app) using inventory-number"

      def search_stockit_items
        records = @packages # security
        if params["searchText"].present?
          records = records.search(
            search_text: params["searchText"],
            item_id: params["itemId"],
            restrict_multi_quantity: params["restrictMultiQuantity"],
            with_inventory_no: true
          )
        end
        params_for_filter = %w[state location associated_package_types storage_type_name].each_with_object({}) { |k, h| h[k] = params[k].presence }
        records = records.filter(params_for_filter)
        records = records.order("packages.id desc").page(params["page"]).per(params["per_page"] || DEFAULT_SEARCH_COUNT)
        packages = ActiveModel::ArraySerializer.new(records,
                                                    each_serializer: stock_serializer,
                                                    root: "items",
                                                    include_order: false,
                                                    include_packages: false,
                                                    include_orders_packages: true,
                                                    include_package_set: bool_param(:include_package_set, true),
                                                    include_images: true).as_json
        render json: { meta: { total_pages: records.total_pages, search: params["searchText"] } }.merge(packages)
      end

      def split_package
        package_splitter = PackageSplitter.new(@package, qty_to_split)
        package_splitter.split!
        send_stock_item_response
      end

      api :PUT, "/v1/packages/1/move", "Move a package's quantity to an new location"
      param_group :operations
      def move
        quantity = params[:quantity].to_i
        Package::Operations.move(quantity, @package, from: params[:from], to: params[:to])
        send_stock_item_response
      end

      api :PUT, "/v1/packages/1/designate", "Designate a package's quantity to an order"
      param_group :operations
      def designate
        quantity = params[:quantity].to_i
        order_id = params[:order_id]

        Package::Operations.designate(@package, quantity: quantity, to_order: order_id)
        send_stock_item_response
      end

      api :PUT, "/v1/packages/1/actions/:action_name", "Executes an action on a package"
      param_group :operations

      def register_quantity_change
        Package::Operations.register_quantity_change(@package,
          quantity: params[:quantity].to_i,
          location: params[:from],
          action: params[:action_name],
          description: params[:description])

        send_stock_item_response
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
            include_images: @package.package_set_id.blank?
          )
        else
          render json: { errors: @package.errors.full_messages }, status: 422
        end
      end

      def add_remove_item
        render nothing: true, status: 204 and return if params[:quantity].to_i.zero?
        response = Package::Operations.pack_or_unpack(
                    container: @package,
                    package: Package.find(params[:item_id]),
                    quantity: params[:quantity].to_i, # quantity to pack or unpack
                    location_id: params[:location_id],
                    user_id: User.current_user.id,
                    task: params[:task]
                  )
        if response[:success]
          render json: { packages_inventories: response[:packages_inventory] }, status: 201
        else
          render json: { errors: response[:errors] }, status: 422
        end
      end

      api :GET, "/v1/packages/1/contained_packages", "Returns the packages nested inside of current package"
      def contained_packages
        container = @package
        contained_pkgs = PackagesInventory.packages_contained_in(container).page(page)&.per(per_page)
        render json: contained_pkgs, each_serializer: stock_serializer, include_items: true,
          include_orders_packages: false, include_storage_type: false,
          include_donor_conditions: false, root: "items"
      end

      api :GET, "/v1/packages/1/parent_containers", "Returns the packages which contain current package"
      def parent_containers
        containers = PackagesInventory.containers_of(@package).page(page)&.per(per_page)
        render json: containers,
          each_serializer: stock_serializer,
          include_items: true,
          include_orders_packages: false,
          include_storage_type: false,
          include_donor_conditions: false,
          include_images: true,
          root: "items"
      end

      def fetch_added_quantity
        entity_id = params[:entity_id]
        render json: { added_quantity: @package&.quantity_contained_in(entity_id) }, status: 200
      end

      private

      def render_order_status_error
        render json: { errors: I18n.t("orders_package.order_status_error") }, status: 403
      end

      def stock_serializer
        Api::V1::StockitItemSerializer
      end

      def remove_stockit_prefix(stockit_inventory_number)
        stockit_inventory_number.gsub(/^x/i, "") unless stockit_inventory_number.blank?
      end

      def package_params
        get_package_type_id_value
        attributes = [
          :allow_web_publish, :box_id, :case_number, :designation_name,
          :detail_id, :detail_type, :donor_condition_id, :grade, :height,
          :inventory_number, :item_id, :length, :location_id, :notes, :order_id,
          :package_type_id, :pallet_id, :pieces, :received_at, :saleable,
          :received_quantity, :rejected_at, :state, :state_event, :stockit_designated_on,
          :stockit_id, :stockit_sent_on, :weight, :width, :favourite_image_id, :restriction_id,
          :expiry_date, :value_hk_dollar, :package_set_id, offer_ids: [],
          packages_locations_attributes: %i[id location_id quantity],
          detail_attributes: [:id, computer_attributes, electrical_attributes,
                              computer_accessory_attributes, medical_attributes].flatten.uniq
        ]

        params.require(:package).permit(attributes)
      end

      def qty_to_split
        (params["package"] && params["package"]["quantity"] || 0).to_i
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

      def medical_attributes
        %i[brand country_id serial_number updated_by_id]
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

      def initialize_package_record
        if is_stock_app?
          @package.donor_condition_id = package_params[:donor_condition_id] if assign_donor_condition?
          @package.inventory_number = inventory_number
          @package
        elsif inventory_number
          assign_values_to_existing_or_new_package
        else
          @package.assign_attributes(package_params)
        end
        @package.storage_type = assign_storage_type
        @package.detail = assign_detail if params["package"]["detail_type"].present?
        @package.received_quantity ||= received_quantity
        @package.offer_id = offer_id
        @package
      end

      def try_inventorize_package(pkg)
        unless PackagesInventory.inventorized?(pkg)
          Package::Operations.inventorize(pkg, location_id)
        end
      end

      # @TODO: remove
      # Case: Stockit changes the location_id
      # We assume aingle location
      #
      def apply_stockit_move(pkg)
        quantity = PackagesInventory::Computer.package_quantity(pkg)
        return if !STOCKIT_ENABLED || location_id.nil? || quantity.zero?

        Package::Operations.move(quantity, pkg, from: pkg.locations.first, to: location_id)
      end

      # @TODO: remove
      # We assume aingle location and orders_package
      #
      def apply_stockit_quantity_change(pkg, current:, previous:)
        OrdersPackage.where(package: pkg).where('quantity > 0').each { |ord_pkg| ord_pkg.update(quantity: current) }
        delta = current - previous
        action = delta.positive? ? PackagesInventory::Actions::GAIN : PackagesInventory::Actions::LOSS
        Package::Operations.register_quantity_change(pkg, quantity: delta.abs, action: action, location: pkg.locations.first)
      end

      # @TODO: remove
      #
      def apply_stockit_dispatch(pkg)

        return unless is_stockit_request? && STOCKIT_ENABLED

        qty = pkg.received_quantity # StockIt only deals with full quantity

        if pkg.stockit_sent_on.nil?
          # Case: stockit undispatched the package
          OrdersPackage.dispatched.where(package: pkg).each do |ord_pkg|
            OrdersPackage::Operations.undispatch(ord_pkg, quantity: qty, to_location: location_id)
          end
        end

        OrdersPackage.designated.where(package: pkg).each do |ord_pkg|
          ord_pkg.cancel if order_id != ord_pkg.order_id
        end

        if order_id.present?
          ord_pkg = OrdersPackage.where(package: pkg, order_id: order_id).first_or_create(state: OrdersPackage::States::DESIGNATED, quantity: qty)
          OrdersPackage::Operations.dispatch(ord_pkg, quantity: qty, from_location: pkg.locations.first) if ord_pkg&.designated? && pkg.stockit_sent_on.present?
        end
      end

      def assign_values_to_existing_or_new_package
        new_package_params = package_params
        GoodcitySync.request_from_stockit = is_stockit_request? # @TODO remove
        @package = existing_package || Package.new()
        delete_params_quantity_if_all_quantity_designated(new_package_params)
        @package.assign_attributes(new_package_params)
        @package.received_quantity = received_quantity
        @package.location_id = location_id
        @package.state = "received"
        @package.order_id = order_id
        @package.inventory_number = inventory_number
        @package.box_id = box_id
        @package.pallet_id = pallet_id
        @package
      end

      def print_count
        params[:labels].to_i
      end

      def received_quantity
        (params[:package][:received_quantity] || params[:package][:quantity]).to_i
      end

      def location_id
        if is_stockit_request? # @TODO remove
          Location.find_by(stockit_id: package_params[:location_id]).try(:id)
        else
          package_params[:location_id]
        end
      end

      def box_id
        Box.find_by(stockit_id: package_params[:box_id]).try(:id)
      end

      def pallet_id
        Pallet.find_by(stockit_id: package_params[:pallet_id]).try(:id)
      end

      def order_id
        if package_params[:order_id]
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

      def assign_detail
        request_from_stockit = GoodcitySync.request_from_stockit
        PackageDetailBuilder.new(
          package_params,
          request_from_stockit
        ).build_or_update_record
      end

      def assign_storage_type
        storage_type_name = params["package"]["storage_type"] || "Package"
        return unless %w[Box Pallet Package].include?(storage_type_name)

        StorageType.find_by(name: storage_type_name)
      end

      def inventory_number
        remove_stockit_prefix(@package.inventory_number)
      end

      def delete_params_quantity_if_all_quantity_designated(new_package_params)
        if new_package_params["quantity"].to_i == @package.total_assigned_quantity
          new_package_params.delete("quantity")
        end
      end
    end
  end
end
