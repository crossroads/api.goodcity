module StockOperations
  PACK_UNPACK_ALLOWED_ACTIONS = %w[pack unpack].freeze

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

    def pack_or_unpack(container:, package: ,location_id:, quantity: , user_id:, task: )
      raise Goodcity::ActionNotAllowedError.new unless PACK_UNPACK_ALLOWED_ACTIONS.include?(task)
      PackUnpack.new(container, package, location_id, quantity, user_id).public_send(task)
    end

    class PackUnpack
      def initialize(container, package, location_id, quantity, user_id)
        @cause = container # box or pallet
        @package = package # item to add or remove
        @location_id = location_id
        @quantity = quantity # quantity to pack or unpack
        @user_id = user_id
      end

      def pack
        return error(I18n.t("box_pallet.errors.adding_box_to_box")) if adding_box_to_a_box?
        return error(I18n.t("box_pallet.errors.item_designated")) if item_designated?
        return error(I18n.t("box_pallet.errors.invalid_quantity")) if invalid_quantity?
        pkg_inventory = pack_or_unpack(PackagesInventory::Actions::PACK)
        response(pkg_inventory)
      end

      def unpack
        pkg_inventory = pack_or_unpack(PackagesInventory::Actions::UNPACK)
        response(pkg_inventory)
      end

      private

      def pack_or_unpack(task)
        return unless @quantity.positive?
        PackagesInventory.new(
          package: @package,
          source: @cause,
          action: task,
          location_id: @location_id,
          user_id: @user_id,
          quantity: quantity(task)
        )
      end

      def quantity(task)
        task.eql?("pack") ? @quantity * -1 : @quantity
      end

      def error(error)
        { errors: [error], success: false }
      end

      def response(pkg_inventory)
        return unless pkg_inventory
        if pkg_inventory.save
          { packages_inventory: pkg_inventory, success: true }
        elsif pkg_inventory.errors
          error(pkg_inventory.errors.full_messages)
        end
      end

      def invalid_quantity?
        @quantity > available_quantity_on_location(@location_id)
      end

      def available_quantity_on_location(location_id)
        PackagesLocation.where(location_id: location_id, package_id: @package.id).first.quantity
      end

      def adding_box_to_a_box?
        @package.box? && @cause.box?
      end

      def item_designated?
        @package.order.presence
      end
    end
  end
end
