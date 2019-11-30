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
      def initialize(quantity, package, from:, to:)
        @quantity = positive_integer(quantity)
        @package = package
        @from = Utils.to_model(from, Location)
        @to = Utils.to_model(to, Location)
      end

      def perform
        secure do
          source_packages_location.decrement(:quantity, @quantity).save
          dest_packages_location.increment(:quantity, @quantity).save
          source_packages_location.destroy if source_packages_location.quantity.zero?
        end
        Stockit::ItemSync.move(@package)
      end

      private

      def positive_integer(n)
        return n if n.positive?
        raise Goodcity::InvalidQuantityError.new(n)
      end

      def source_packages_location
        @source ||= PackagesLocation.find_by(package: @package, location: @from)
      end

      def dest_packages_location
        @dest ||= PackagesLocation.where(package: @package, location: @to).first_or_create(quantity: 0)
      end

      def secure
        source = source_packages_location
        raise MissingQuantityError if source.nil? || source.quantity < @quantity
        ActiveRecord::Base.transaction { yield }
      end
    end

    def move(quantity, package, from:, to:)
      Move.new(quantity, package, from: from, to: to).perform
    end

    module_function :move
  end
end
