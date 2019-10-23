# Centralizing location operations to facilitate upcoming migration
# away from packages_locations to packages_inventory
#
# @example
#   Operations::move(2, package_a)
#     .from(location_a)
#     .to(location_b)
#
module LocationOperations
  extend ActiveSupport::Concern

  module Operations

    # --- Moving a package from one location to another
    class Move

      def initialize(quantity, package)
        @quantity = quantity
        @package = package
      end

      def from(location)
        @from = Utils::to_model(location, Location)
        self
      end

      def to(location)
        @to = Utils::to_model(location, Location)
        apply_change
      end

      private

      # --- Helpers

      def source_packages_location
        @source ||= PackagesLocation.find_by(package: @package, location: @from)
      end

      def dest_packages_location
        @dest ||= PackagesLocation
          .where(package: @package, location: @to)
          .first_or_create(quantity: 0)
      end

      # --- Transaction

      def secure
        source = source_packages_location
        raise MISSING_QTY if source.nil? || source.quantity < @quantity
        ActiveRecord::Base.transaction { yield }
      end

      def apply_change
        secure do
          source_packages_location.decrement!(:quantity, @quantity)
          dest_packages_location.increment!(:quantity, @quantity)
          source_packages_location.destroy if source_packages_location.quantity.zero?
        end
      end

      MISSING_QTY = StandardError.new(I18n.t('operations.move.not_enough_at_source'))
    end

    def move(quantity, package)
      Move.new(quantity, package)
    end

    module_function :move
  end
end