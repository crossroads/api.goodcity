# Takes an existing package and updates it's designation from Stockit
# Goodcity::PackageDesignator.run(inventory_number: 'F123245', order_code: 'GC-12324', dispatched: false)

module Goodcity

  class PackageDesignator

    def initialize(options)
      @inventory_number = options[:inventory_number]
      @order_code = options[:order_code]
      @dispatched = options[:dispatched]
      if @inventory_number.nil? or @order_code.nil? or @dispatched.nil?
        raise "Please ensure inventory_number, order_code, dispatched options are set."
      end
    end

    def self.run(options)
      new(options).update
    end

    def update
      package = Package.where(inventory_number: @inventory_number).first
      order = Order.where(code: @order_code)
      if package and order
        designate!(package, order, @dispatched)
      elsif package.nil?
        puts "#{@inventory_number} package not found. Could not designate"
      elsif order.nil?
        puts "#{@order} order not found. Could not designate."
      end
    end

    private

    def fix_designation(package, order, dispatched)
      # cancel existing_orders
      existing_orders = package.orders_packages.select{ |op| op.state != 'cancelled' }.map(&:order).uniq
      existing_orders.each do |existing_order|
        # undispatch, cancel
      end
      Package::Operations.designate(package, quantity: package.received_quantity, to_order: order)
      if dispatched
        location = package.packages_locations.first.location
        Package::Operations.dispatch(package.orders_packages.first, quantity: package.received_quantity, from_location: location)
      end
    end


    def log(msg)
      puts "#{@inventory_number},msg"
    end


  end

end