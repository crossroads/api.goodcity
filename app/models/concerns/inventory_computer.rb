module InventoryComputer
  extend ActiveSupport::Concern

=begin
  Adds a sub module containing all the needed SQL computations

  @example

  PackagesInventory::Computer.compute_quantity.of(package).as_of_now
  PackagesInventory::Computer.compute_quantity.where({ package_id: 1 }).as_of_now
  PackagesInventory::Computer.package_quantity(package2).now
  PackagesInventory::Computer.package_quantity(package1).now
  PackagesInventory::Computer.package_quantity(package1).as_of(3.years.ago)
  PackagesInventory::Computer.package_quantity(package1).as_of(5.months.ago)
  PackagesInventory::Computer.quantity.now
  PackagesInventory::Computer.dispatch_quantity.now.abs
  PackagesInventory::Computer.inventory_quantity.now
  PackagesInventory::Computer.inventory_quantity.as_of(6.months.ago)
  PackagesInventory::Computer.location_quantity(location2).as_of(4.months.ago)
  PackagesInventory::Computer.location_quantity(location2).now
  PackagesInventory::Computer.inventory_quantity.of(package2).as_of(6.months.ago)
  PackagesInventory::Computer.dispatch_quantity.of(package2).as_of(6.months.ago)
=end
  class Computer

    class << self
      #
      # Main entry point. Sums up the quantity field of the inventory table
      #
      # @param [String|Hash] query the properties to filter on
      # @return [SumAsOf] a quantity resolver
      #
      def compute_quantity
        SumAsOf.new(PackagesInventory)
      end

      def quantity_of(record)
        compute_quantity.of(record)
      end

      alias_method :package_quantity, :quantity_of
      alias_method :location_quantity, :quantity_of

      def designated_quantity(package)
        OrdersPackage.designated.where(package: package).sum(:quantity)
      end

      def available_quantity(package)
        package_quantity(package) - designated_quantity(package)
      end

      # Creates gain_quantity, loss_quantity, dispatch_quantity, ...
      PackagesInventory::ALLOWED_ACTIONS.each do |action|
        define_method("#{action}_quantity") do
          compute_quantity.where("action = (?)", action)
        end
      end
    end

    #
    # Time-aware, where-able numeric value
    #
    class SumAsOf < ComputableNumeric
      include Whereable

      def initialize(model)
        use_model(model)
      end

      def compute
        as_of(Time.now)
      end

      def as_of(time)
        relation.where("#{@model.table_name}.created_at <= (?)", time).sum(:quantity).abs
      end

      def of(model)
        where("#{model.class.name.underscore}_id = (?)", Utils.to_id(model))
      end

      alias_method :current, :to_i
      alias_method :now, :to_i
      alias_method :as_of_now, :to_i
    end
  end
end
