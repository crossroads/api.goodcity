
# INCOMPLETE don't load!

module Goodcity
  class DispatchPackage

    def dispatch_package(package, order)
      ActiveRecord::Base.transaction do
        # Re-open order if necessary by tweaking state and not touching timestamps
        old_state = nil
        if !Order::ACTIVE_STATES.include?(order.state)
          old_state = order.state
          order.update_column(:state, 'dispatching')
        end

        # Designate and dispatch package
        location = package.packages_locations.first.location
        orders_package = Package::Operations.designate(package, quantity: package.received_quantity, to_order: order)
        OrdersPackage::Operations.dispatch(orders_package, quantity: package.received_quantity, from_location: location)

        # Fix timestamps and order state
        designation_time = order.closed_at || order.updated_at || order.created_at
        orders_package.update_columns(created_at: designation_time, updated_at: designation_time, sent_on: designation_time)
        order.update_column(:state, old_state) if old_state.present?
      end
    end

    # packages_to_dispatch = [ ['E59443', 'L19679'] ]

    # packages_to_dispatch.each do |inventory_number, order_code|
    #   order = Order.where(code: order_code)
    #   if order.size == 1
    #     package = Package.where(inventory_number: inventory_number)
    #     if package.size == 1
    #       dispatch_package(package.first, order.first)
    #     else
    #       puts "Can't find package #{inventory_number}"
    #     end
    #   else
    #     puts "Can't find order #{order_code}"
    #   end
    # end

  end
end