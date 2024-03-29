module InventoryComputer
  extend ActiveSupport::Concern

  ##
  # Adds a sub module containing all the needed SQL computations
  #
  class Computer
    PACKING_ACTIONS     = [PackagesInventory::Actions::PACK, PackagesInventory::Actions::UNPACK].freeze
    DISPATCHING_ACTIONS = [PackagesInventory::Actions::DISPATCH, PackagesInventory::Actions::UNDISPATCH].freeze

    class << self
      ##
      # Main entry point. Sums up the quantity field of the inventory table at a certain point in time
      #
      # @param [String|Hash] query the properties to filter on
      # @return [SumAsOf] a quantity resolver
      #
      def historical_quantity
        SumAsOf.new(PackagesInventory)
      end

      def quantity_where(query)
        historical_quantity.where(query).as_of_now
      end

      def package_quantity(package, location: nil)
        res = historical_quantity.where(package: package)
        res = res.where(location_id: Utils.to_id(location)) if location
        res.as_of_now
      end

      def location_quantity(location)
        quantity_where(location: location)
      end

      def total_quantity_in(source)
        historical_quantity
          .where(source: source, action: PACKING_ACTIONS)
          .as_of_now
      end

      def quantity_contained_in(container:, package: nil)
        res = historical_quantity.where(source: container, action: PACKING_ACTIONS)
        res = res.where(package_id: Utils.to_id(package)) if package.present?
        res.as_of_now
      end

      def designated_quantity_of_old(package, to_order: nil)
        query = OrdersPackage.where(package: package).where.not(state: OrdersPackage::States::CANCELLED)
        query = query.where(order: to_order) if to_order.present?
        query.reduce(0) { |sum, op| sum + op.quantity - dispatched_quantity(orders_package: op) }
      end

      # Get the orders_packages related to this package and order (optional)
      # Using PackagesInventory, get dispatched quantities for each of these orders_packages and build a mapping table
      #   {orders_package_id => dispatched qty } e.g. {21=>-2, 23=>-1, 28=>-5}
      # For each orders_package: subtract the Packages Inventory dispatched quantity from the designated quantity
      #   to work out the overall remainder that is designated
      def designated_quantity_of(package, to_order: nil)
        op_query = OrdersPackage.where(package: package).where.not(state: OrdersPackage::States::CANCELLED)
        op_query = op_query.where(order: to_order) if to_order.present?
        dispatched_quantity_map = Hash[
          PackagesInventory.select('source_id, sum(quantity)')
            .where(action: DISPATCHING_ACTIONS)
            .where(source_type: 'OrdersPackage', source_id: op_query.pluck('id'))
            .group('source_id').map{|o| [o['source_id'], o['sum'].abs] } ]
        op_query.reduce(0) { |sum, op| sum + op.quantity - (dispatched_quantity_map[op.id] || 0) }
      end

      def dispatched_quantity(package: nil, orders_package: nil)
        res = historical_quantity.where(action: DISPATCHING_ACTIONS)
        res = res.where(package: package) if package.present?
        res = res.where(source: orders_package) if orders_package.present?
        res.as_of_now
      end

      ##
      # Returns quantity which not designated
      #
      # @param [Package] package the package to compute the quantity of
      # @return [Integer] the on-hand undesignated quantity
      #
      def available_quantity_of(package)
        package_quantity(package) - designated_quantity_of(package)
      end

      def total_quantity
        historical_quantity.as_of_now
      end

      def on_hand_packed_quantities_for(package)
        res = PackagesInventory.joins("INNER JOIN packages on packages.id = packages_inventories.source_id and packages_inventories.source_type = 'Package'")
        res = res.select('packages_inventories.*')
        res = res.where(packages_inventories: { package_id: package.id,
                                                action: PACKING_ACTIONS })
        res = res.where.not(packages: { on_hand_quantity: 0 })
                 .group('packages.storage_type_id').sum(:quantity)
        res = quantify_by_storage_type(res)
        res
      end

      def package_quantity_summary(package)
        {
          on_hand_quantity: package_quantity(package),
          available_quantity: available_quantity_of(package),
          dispatched_quantity: dispatched_quantity(package: package),
          designated_quantity: designated_quantity_of(package),
        }.merge(on_hand_packed_quantities_for(package))
      end

      def update_package_quantities!(package)
        package.secured_transaction do
          package.assign_attributes package_quantity_summary(package)
          package.save!
        end
      end

      private

      def quantify_by_storage_type(inventories)
        {
          on_hand_boxed_quantity: inventories[StorageType.box_type_id]&.abs || 0,
          on_hand_palletized_quantity: inventories[StorageType.pallet_type_id]&.abs || 0
        }
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
        as_of(nil)
      end

      def as_of(time)
        res = relation
        res = res.where("#{@model.table_name}.created_at <= (?)", time) unless time.blank?
        res.sum(:quantity).abs
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
