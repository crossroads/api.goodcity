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
    # @param [Location|String] the location to place the package in
    #
    def uninventorize(package_inventory_id)
      last_action = PackagesInventory.find(package_inventory_id)
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
    def register_loss(package, quantity:, location_id: nil, action: 'loss', description: nil)
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

      PackagesInventory.public_send("append_#{action}" , {
        package: package,
        quantity: quantity.abs * -1,
        location_id: location_id,
        description: description,
      })
    end

    def perform_action(package, quantity:, location_id:, action: 'loss', description: nil)
      if PackagesInventory::DECREMENTAL_ACTIONS.include?(action)
        register_loss(package,
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

  end
end
