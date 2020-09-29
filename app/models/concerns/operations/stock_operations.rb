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
    # @param [Package] the package to inventorize
    # @param [Location|String] the location to place the package in
    #
    def inventorize(package, location)
      package.inventory_lock do
        assert_can_inventorize!(package, location)

        PackagesInventory.append_inventory(
          package_id:   package.id,
          quantity:     package.received_quantity,
          location_id:  Utils.to_id(location)
        )
      end
      package.reload
    end

    def assert_can_inventorize!(package, location)
      raise Goodcity::AlreadyInventorizedError if PackagesInventory.inventorized?(package)
      raise Goodcity::BadOrMissingRecord.new(Location) unless Utils.record_exists?(location, Location)
      raise Goodcity::BadOrMissingField.new(:inventory_number) unless package.inventory_number.present?
    end

    ##
    # Undo the latest inventory action
    # Will fail if
    #
    # @raise [Goodcity::UninventoryError] thrown if actions were taken since the initial inventory action
    #
    # @param [Package] the package to inventorize
    # @param [Location|String] the location to place the package in
    #
    def uninventorize(package)
      package.inventory_lock do
        last_action = PackagesInventory.order('id DESC').where(package: package).limit(1).first
        raise Goodcity::UninventoryError if last_action.blank? || !last_action.inventory?
        last_action.undo
      end
      package.reload
    end

    ##
    # Registers the gain of package
    #
    # @param [Package] package to be gained
    # @param [Integer] quantity that is added
    # @param [Location|Id] to the location to add the quantity (or its id)
    #
    def register_gain(package, quantity:, location: nil, action: "gain", description: nil, source: nil)
      package.inventory_lock do
        raise Goodcity::NotInventorizedError unless PackagesInventory.inventorized?(package)
        PackagesInventory.public_send("append_#{action}", {
          package: package,
          quantity: quantity.abs,
          location: Utils.to_model(location, Location),
          description: description,
          source: source
        })
        package.reload
      end
    end

    ##
    # Registers the loss of some package
    #
    # @param [Package] package the package that went missing
    # @param [Integer] quantity the quantity that was lost
    # @param [Location|Id] from_location the location to negate the quantity from(or its id)
    #
    def register_loss(package, quantity:, location: nil, action: 'loss', description: nil, source: nil)
      package.inventory_lock do
        available_count = PackagesInventory::Computer.available_quantity_of(package)

        if quantity.abs > available_count
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
          location: Utils.to_model(location, Location),
          description: description,
          source: source
        })
        package.reload
      end
    end

    ##
    # Registers either a gain or a loss action depending on the change value
    #
    # @param [Package] package the package that had a quantity change
    # @param [Integer] quantity: the quantity that was lost
    # @param [Location|Id] location: the location to add the quantity to (or its id)
    # @param [String] action: the inventory action (optional)
    # @param [String] description: notes to detail the action
    #
    def register_quantity_change(package, quantity:, location:, action:, description: nil, source: nil)
      return package if quantity.zero?

      params = {
        quantity: quantity,
        location: Utils.to_model(location, Location),
        action: action,
        description: description,
        source: source
      }

      if PackagesInventory::QUANTITY_LOSS_ACTIONS.include?(action)
        register_loss(package, params)
      elsif PackagesInventory::QUANTITY_GAIN_ACTIONS.include?(action)
        register_gain(package, params)
      else
        raise Goodcity::ActionNotAllowedError.new
      end
      package.reload
    end

    def pack_or_unpack(container:, package: ,location_id:, quantity: , user_id:, task: )
      package.inventory_lock do
        raise Goodcity::ActionNotAllowedError.new unless PackUnpack.action_allowed?(task)
        PackUnpack.new(container, package, location_id, quantity, user_id).public_send(task)
      end
    end

    class PackUnpack
      def initialize(container, package, location_id, quantity, user_id)
        @cause = container # box or pallet
        @package = package # item to add or remove
        @location_id = location_id
        @quantity = quantity # quantity to pack or unpack
        @user_id = user_id
      end

      # @TODO Raise Goodcity errors instead of returning json
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
        raise Goodcity::InvalidQuantityError.new(@quantity) unless @quantity.positive?
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
        available_quantity.positive?
      end

      # checks if the addable quantity is greater than available quantity.
      def invalid_quantity?
        @quantity > available_quantity
      end

      def available_quantity
        @available_quantity ||= PackagesInventory::Computer.available_quantity_of(@package)
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
