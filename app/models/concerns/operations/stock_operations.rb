module StockOperations
  extend Composite

  compose_module :Operations do

    module_function


    ##
    # Adds a package to the inventory
    #
    #
    # @raise [Goodcity::AlreadyInventorizedError] thrown if trying to inventorize twice
    #
    # @param [Package|String] the package to inventorize or its id
    # @param [Location|String] the location to place the package in
    #
    def inventorize(package, location)
      last = PackagesInventory.order('id DESC').where(package: package).limit(1).first

      raise Goodcity::AlreadyInventorizedError if last.present? && !last.uninventory?

      PackagesInventory.append_inventory(
        package:  package,
        quantity: package.received_quantity,
        location: location
      )
    end

    ##
    # Undo the latest inventory action
    # Will fail if
    #
    # @raise [Goodcity::UninventoryError] thrown if actions were taken since the initial inventory action
    #
    # @param [Package|String] the package to inventorize or its id
    # @param [Location|String] the location to place the package in
    #
    def uninventorize(package)
      last_action = PackagesInventory.order('id DESC').where(package: package).limit(1).first
      raise Goodcity::UninventoryError if last_action.blank? || !last_action.inventory?
      last_action.undo
    end

    ##
    # Registers the loss of some package
    #
    # @param [Package] package the package that went missing
    # @param [Integer] quantity the quantity that was lost
    # @param [Location|Id] from the location to negate the quantity from(or its id)
    #
    def register_loss(package, quantity:, from_location:)
      available_count = PackagesInventory::Computer.available_quantity_of(package)

      if (quantity > available_count)
        designated_count = PackagesInventory::Computer.designated_quantity_of(package)
        if designated_count.positive?
          orders = package.orders_packages.designated.map(&:order).uniq
          raise Goodcity::QuantityDesignatedError.new(orders)
        else
          raise Goodcity::InsufficientQuantityError.new(quantity)
        end
      end

      PackagesInventory.append_loss(
        package: package,
        quantity: quantity.abs * -1,
        location: from_location
      )
    end

    def pack_or_unpack(params, user_id)
      raise ActionNotAllowedError.new unless PackUnpack::ALLOWED_ACTIONS.include?(params[:task])
      PackUnpack.new(params, user_id).public_send(params[:task])
    end

    class PackUnpack
      ALLOWED_ACTIONS = %w[pack unpack].freeze

      def initialize(params, user_id)
        @cause = Package.find(params[:id]) # box or pallet
        @item = Package.find(params[:item_id]) # item to add or remove
        @user_id = user_id
        @location_id = params[:location_id]
        @quantity = params[:quantity].to_i # quantity to pack or unpack
      end

      def pack
        pkg_inventory = pack_or_unpack(PackagesInventory::Actions::PACK)
        response(pkg_inventory)
      end

      def unpack
        pkg_inventory = pack_or_unpack(PackagesInventory::Actions::UNPACK)
        response(pkg_inventory)
      end

      def response(pkg_inventory)
        if pkg_inventory.save
          { packages_inventory: pkg_inventory, success: true }
        else pkg_inventory.errors
          { errors: pkg_inventory.errors.full_messages, success: false }
        end
      end

      private

      def pack_or_unpack(task)
        PackagesInventory.new(
          package: @item,
          source: @cause,
          action: task,
          location_id: @location_id,
          user_id: @user_id,
          quantity: quantity(task)
        )
      end

      def quantity(task)
        return unless @quantity
        task.eql?("pack") ? @quantity * -1 : @quantity
      end
    end

    # --- Exceptions

    class OperationsError < StandardError; end

    class MissingQuantityRequiredError < OperationsError
      def initialize(orders)
        order_text = orders.count == 1 ? orders.first.code : "#{orders.count}x"
        super(I18n.t('operations.mark_lost.required_for_orders', orders: order_text))
      end
    end

    class ActionNotAllowedError < OperationsError
      def initialize()
        super(I18n.t("operations.generic.action_not_allowed"))
      end
    end
  end
end
