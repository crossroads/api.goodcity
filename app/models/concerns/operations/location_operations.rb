# Centralizing location operations to facilitate upcoming migration
# away from packages_locations to packages_inventory
#
# @example
#   Operations::move(2, package_a, from: A, to: B)
#
module LocationOperations
  extend ActiveSupport::Concern

  module Operations
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
          raise MISSING_QTY if available_qty < @quantity
          decrement_origin
          increment_destination
        end
        Stockit::ItemSync.move(@package)
      end

      private

      def positive_integer(n)
        return n if n.positive?
        raise Goodcity::InvalidQuantityError.new(n)
      end

      def increment_destination
        PackagesInventory.create(
          package: @package,
          quantity: @quantity,
          action: PackagesInventory::Actions::GAIN,
          source: @cause,
          location: @to,
          user: author
        )
      end

      def decrement_origin
        PackagesInventory.create(
          package: @package,
          quantity: -1 * @quantity,
          action: PackagesInventory::Actions::LOSS,
          source: @cause,
          location: @from,
          user: author
        )
      end

      def author
        User.current_user || User.system_user
      end

      def available_qty
        PackagesInventory::Computer
          .package_quantity(@package)
          .where({ location: @from })
          .as_of_now
      end
    end

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

    module_function :move
  end
end
