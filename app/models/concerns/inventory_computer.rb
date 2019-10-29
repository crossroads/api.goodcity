module InventoryComputer
  extend ActiveSupport::Concern

  # Adds a sub module containing all the needed SQL computations
  #
  # @example
  #
  # PackagesInventory::Computer.quantity_where({ package_id: 1 }).as_of_now
  # PackagesInventory::Computer.package_quantity(package2).now
  # PackagesInventory::Computer.package_quantity(package1).now
  # PackagesInventory::Computer.package_quantity(package1).as_of(3.years.ago)
  # PackagesInventory::Computer.package_quantity(package1).as_of(5.months.ago)
  # PackagesInventory::Computer.total_quantity.now
  # PackagesInventory::Computer.total_quantity.now
  # PackagesInventory::Computer.dispatch_quantity.now.abs
  # PackagesInventory::Computer.inventory_quantity.now
  # PackagesInventory::Computer.inventory_quantity.as_of(6.months.ago)
  # PackagesInventory::Computer.total_quantity.as_of(6.months.ago)
  # PackagesInventory::Computer.location_quantity(location2).as_of(4.months.ago)
  # PackagesInventory::Computer.location_quantity(location2).now
  # PackagesInventory::Computer.inventory_quantity_of_package(package2).as_of(6.months.ago)
  #
  class Computer
    QUERYABLE_FIELDS = {
      location: { column: 'location_id' },
      package:  { column: 'package_id' },
      action:   {
        column: 'action',
        presets: Hash[
          PackagesInventory::ALLOWED_ACTIONS.map { |act| [act, act] }
        ]
      }
    }.freeze

    # Main entry point. Sums up the quantity field
    #
    # @param [String|Hash] query the properties to filter on
    #
    # @return [SumAsOf] a quantity resolver
    #
    def self.quantity_where(*query)
      SumAsOf.new(query)
    end


    # Main entry point. Sums up the quantity field
    # Shorthand for quantity_where({})
    #
    # @return [SumAsOf] a quantity resolver
    #
    def self.total_quantity
      quantity_where
    end

    # --- HELPERS

    # Creates an alias method with default arguments
    def self.bind_method(method_name, root_method, *default_args)
      define_singleton_method(method_name) { |*args| send(root_method, *(default_args + args)) }
    end

    # Creates a method that chains a query to it another method
    def self.build_query_method(method_name, root_method, column)
      define_singleton_method(method_name) { |arg| send(root_method).where("#{column} = (?)", arg) }
    end

    # Iterates through the fields, and creates shorthand methods for each
    def self.build_shorthand_methods(root_method, fields, &namer)
      fields.each do |name, field|
        presets       = field[:presets] || {}
        other_fields  = fields.except(name)
        method_name   = namer.call(name)

        # Shorthand method
        build_query_method(method_name, root_method, field[:column])

        presets.each do |preset_name, preset_value|
          preset_func_name = namer.call(preset_name)

          # Same shorthand method with argument pre-filled
          bind_method(preset_func_name, method_name, preset_value)

          # Sub-shorthands pointing to other fields
          build_shorthand_methods(preset_func_name, other_fields) do |subname|
            "#{preset_func_name}_of_#{subname}".to_sym
          end
        end
      end
    end

    # --- Run the helper method generation
    build_shorthand_methods(:quantity_where, QUERYABLE_FIELDS) { |name| "#{name}_quantity".to_sym }

    # Time-aware quantity resolver
    #
    # Is initialized with a filter, either SQL or a Hash, and returns the
    # quantity that matches that filter at a specific moment in time
    #
    # @example
    #
    #   Sum.new({ package_id: pkg.id }).current()
    #   Sum.new({ package_id: pkg.id }).as_of(1.month.ago)
    #   Sum.new({ package_id: pkg.id }).where(...).as_of(1.month.ago)
    #
    class SumAsOf
      def initialize(*query)
        where(*query)
      end

      def where(*query)
        @res ||= PackagesInventory.where(nil)
        @res = @res.where(*query) if query.length.positive?
        self
      end

      def as_of(time)
        where('created_at <= (?)', time)
        @res.sum(:quantity)
      end

      def current
        as_of(Time.now)
      end

      alias_method :now, :current
      alias_method :as_of_now, :current
    end
  end
end
