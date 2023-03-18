module Api::V1
    class PackageOperationsSerializer < ApplicationSerializer
      embed :ids, include: true

      # Used when we split, move, designate, gain/lose a package
      # Returns ony changed data as the full serializer gets very
      # slow for large quantity packages (e.g. many designations)

      # Options
      # @options[:action]       - controller action: split_package, move, designate, register_quantity_change
      # @options[:order_id]     - scope orders_packages to a specific order. Much faster if package contains hundreds of designations

      # Used for the following Package operations
      # - split_package - returns package, packages_locations
      # - move          - returns package quantities, packages_locations
      # - designate     - returns package, orders_packages
      # - register_quantity_change (gain/loss) - returns package quantities, package_locations

      # ----------------------------
      #   Attributes
      # ----------------------------

      attributes :id,
        :state, :updated_at, :received_quantity, :on_hand_quantity,
        :available_quantity, :designated_quantity, :dispatched_quantity,
        :on_hand_boxed_quantity, :on_hand_palletized_quantity,
        :max_order_quantity,
        :orders_packages

      # ----------------------------
      #   Relationships
      # ----------------------------
      has_many :orders_packages, serializer: OrdersPackageSerializer
      has_many :packages_locations, serializer: PackagesLocationSerializer

      def orders_packages
        if @options[:order_id].present?
          object.orders_packages.where(order_id: @options[:order_id])
        else
          object.orders_packages # slow for packages with hundreds of designations
        end
      end

      def include_orders_packages?
        action = (@options[:action] || "").to_s
        %w( designate ).include?(action)
      end

      def include_packages_locations?
        action = (@options[:action] || "").to_s
        %w( split_package move register_quantity_change ).include?(action)
      end

    end
  end
