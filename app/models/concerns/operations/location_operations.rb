# Centralizing location operations to facilitate upcoming migration
# away from packages_locations to packages_inventory
#
# @example
#   Operations::move(2, package_a, from: A, to: B)
#
module LocationOperations
  extend Composite

  compose_module :Operations do
    module_function

    ##
    # Moves a package from a location to another through Packages
    #
    # @param [Integer] quantity the amount to move
    # @param [Package] package the package we want to move
    # @param [Location|Id] from the location to move out of (or its id)
    # @param [Location|Id] to the location to move into (or its id)
    # @param [Model] cause the source model that caused the move
    #
    def move(quantity, package, from:, to:, cause: nil)
      Move.new(quantity, package, from: from, to: to, cause: cause).perform
    end

    # --- Moving a package from one location to another
    class Move
      def initialize(quantity, package, from:, to:, cause: nil)
        @quantity = positive_integer(quantity)
        @package = package
        @from = Utils.to_model(from, Location)
        @to = Utils.to_model(to, Location)
        @cause = cause
      end

      def perform
        return if @quantity.zero?

        PackagesInventory.secured_transaction do
          raise Goodcity::MissingQuantityError if qty_at_source < @quantity
          decrement_origin
          increment_destination
        end
        Stockit::ItemSync.move(@package) if STOCKIT_ENABLED
      end

      private

      def positive_integer(n)
        return n if n.positive?
        raise Goodcity::InvalidQuantityError.new(n)
      end

      def increment_destination
        register_change(@to, @quantity)
      end

      def decrement_origin
        register_change(@from, -1 * @quantity)
      end

      def register_change(location, qty_change)
        PackagesInventory.create(
          package: @package,
          quantity: qty_change,
          action: PackagesInventory::Actions::MOVE,
          source: @cause,
          location: location,
          user: author
        )
      end

      def author
        User.current_user || User.system_user
      end

      def qty_at_source
        PackagesInventory::Computer.quantity_where(package: @package, location: @from)
      end
    end
  end
end
