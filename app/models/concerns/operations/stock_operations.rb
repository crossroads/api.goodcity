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
      raise Goodcity::BadOrMissingRecord.new(Location) unless Utils.record_exists?(location, Location)
      raise Goodcity::BadOrMissingField.new(:inventory_number) unless package.inventory_number.present?
      
      PackagesInventory.append_inventory(
        package_id:   package.id,
        quantity:     package.received_quantity,
        location_id:  Utils.to_id(location)
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
    # @param [Location|Id] from_location the location to negate the quantity from(or its id)
    #
    def register_loss(package, quantity:, location_id: nil, action: 'loss', description: nil)
      available_count = PackagesInventory::Computer.available_quantity_of(package)

      if (quantity.abs > available_count)
        designated_count = PackagesInventory::Computer.designated_quantity_of(package)
        if designated_count.positive?
          orders = package.orders_packages.designated.map(&:order).uniq
          raise Goodcity::QuantityDesignatedError.new(orders)
        else
          raise Goodcity::InsufficientQuantityError.new(quantity)
        end
      end

      PackagesInventory.public_send("append_#{action}", {
        package: package,
        quantity: quantity.abs * -1,
        location_id: location_id,
        description: description
      })
    end


    ##
    # Registers the gain of some package
    #
    # @param [Package] package the package that went missing
    # @param [Integer] quantity the quantity that was lost
    # @param [Location|Id] to_location the location to add the quantity to (or its id)
    #
    def register_gain(package, quantity:, to_location:)
      raise Goodcity::NotInventorizedError unless PackagesInventory.inventorized?(package)
      PackagesInventory.append_gain(
        package: package,
        quantity: quantity,
        location: Utils.to_model(to_location, Location)
      )
    end

    ##
    # Registers either a gain or a loss action depending on the change value
    #
    # @param [Package] package the package that went missing
    # @param [Integer] quantity the quantity that was lost
    # @param [Location|Id] location the location to add the quantity to (or its id)
    #
    def register_quantity_change(package, delta:, location:)
      return if delta.zero?
      return delta.positive? ?
        register_gain(package, quantity: delta, to_location: location) :
        register_loss(package, quantity: delta, from_location: location)
    end

    def perform_action(package, quantity:, location_id:, action: 'loss', description: nil)
      if PackagesInventory::QUANTITY_LOSS_ACTIONS.include?(action)
        register_loss(
          package,
          quantity: quantity,
          location_id: location_id,
          action: action,
          description: description)
      else
        raise Goodcity::ActionNotAllowedError.new
      end
    end

    def pack_or_unpack(container:, package: ,location_id:, quantity: , user_id:, task: )
      raise Goodcity::ActionNotAllowedError.new unless PackUnpack.action_allowed?(task)
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
        return error(I18n.t("box_pallet.errors.disable_addition")) unless addition_allowed?
        return error(I18n.t("box_pallet.errors.invalid_quantity")) if invalid_quantity?

        pkg_inventory = pack_or_unpack(PackagesInventory::Actions::PACK)
        response(pkg_inventory)
      end

      def unpack
        return error(I18n.t("box_pallet.errors.disable_if_unavailable")) unless operation_allowed?
        pkg_inventory = pack_or_unpack(PackagesInventory::Actions::UNPACK)
        response(pkg_inventory)
      end

      private

      def self.action_allowed?(task)
        GoodcitySetting.enabled?("stock.allow_box_pallet_item_addition") &&
        PACK_UNPACK_ALLOWED_ACTIONS.include?(task)
      end

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

      # calculate quantity based on the operation
      def quantity(task)
        task.eql?("pack") ? @quantity * -1 : @quantity
      end

      def error(error)
        { errors: [error], success: false }
      end

      # checks if the box/pallet is on hand, to perform operations.
      def operation_allowed?
        @cause.on_hand_quantity.positive?
      end

      # checks if the package has available quantity to add inside a box.
      def addition_allowed?
        @package.available_quantity.positive?
      end

      # checks if the addable quantity is greater than available quantity.
      def invalid_quantity?
        @quantity > @package.available_quantity
      end

      def response(pkg_inventory)
        return unless pkg_inventory
        if pkg_inventory.save
          { packages_inventory: pkg_inventory, success: true }
        elsif pkg_inventory.errors
          error(pkg_inventory.errors.full_messages)
        end
      end

      # checks if a box is added to a box.
      def adding_box_to_a_box?
        @package.box? && @cause.box?
      end
    end

  end
end
