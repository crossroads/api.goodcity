require "#{Rails.root}/spec/support/inventory_initializer.rb"

#
# Order state prerequisites
#

Given(/^I have Orders with states of type: "([^"]*)"/) do |state_type|
  @order_states = Order.const_get(state_type.upcase)
end

Given(/^I have Orders of state "([^"]*)"/) do |states|
  @order_states = states.split('|')
end

#
# Building the orders_packages
#

# We provide a list of states for the orders_packages
And(/^Their OrdersPackages are of state "([^"]*)"$/) do |orders_package_states|
  op_states = orders_package_states.split('|')
  stub_request(:post, 'http://www.example.com/api/v1/items').to_return(status: 200, body: '', headers: {})
  @orders_packages_per_state = @order_states.reduce({}) do |dict, state|
    dict[state] = op_states.map do |op_state|
      create(
        :orders_package,
        order: create(:order, state: state),
        state: op_state
      )
    end
    dict
  end
end

And(/^Their OrdersPackages are partially dispatched$/) do
  @orders_packages_per_state.each do |_, order_packages|
    order_packages.each do |op|
      op.dispatched_quantity = 1
    end
  end
end

# We pass in quantity properties and state as a table
And(/^Their OrdersPackages have the following stock properties$/) do |qty_table|
  properties = qty_table.hashes
  location = create :location
  @orders_packages_per_state = @order_states.reduce({}) do |dict, state|
    dict[state] = properties.map do |row|
      remaining_qty = row['On-site Quantity'].to_i
      requested_qty = row['Requested Quantity'].to_i
      received_qty  = row['Received Quantity'].to_i
      # Build the package
      pkg = create(:package, received_quantity: received_qty)
      InventoryInitializer.initialize_inventory(pkg, location: location)

      # Dispatch some quantity in order to reach the desired "Remaining Quantity"
      already_dispatched_qty = received_qty - remaining_qty
      if already_dispatched_qty.positive?
        create(:orders_package, :with_inventory_record, state: 'dispatched', package: pkg, quantity: already_dispatched_qty)
      end

      # Create the actual orders_package to test on
      orders_package = create(
        :orders_package,
        :with_inventory_record,
        state: row['State'],
        quantity: requested_qty,
        order: create(:order, state: state),
        package: pkg.reload
      )
      expect(pkg.reload.on_hand_quantity).to eq(remaining_qty)
      orders_package
    end
    dict
  end
end

#
# Asserting the actions
#

Then(/^They should have no actions available$/) do
  orders_packages = @orders_packages_per_state.values.flatten
  orders_packages.each do |orders_package|
    expect(orders_package.allowed_actions.length).to eq(0)
  end
end

Then(/^They should have the "([^"]*)" actions (enabled|disabled)$/) do |actions_str, enable_str|
  actions = actions_str.split('|')
  enabled = enable_str == "enabled"
  orders_packages = @orders_packages_per_state.values.flatten
  orders_packages.each do |orders_package|
    actions.each do |name|
      expect(orders_package.allowed_actions).to include(name: name, enabled: enabled)
    end
  end
end

Then(/^They should respectively have the following action status$/) do |action_data_table|
  expected_statuses = action_data_table.hashes

  @orders_packages_per_state.each do |state, orders_packages|
    orders_packages.each_with_index do |orders_package, idx|
      expected_status = expected_statuses[idx]
      expect(orders_package.allowed_actions).to include(
        name: expected_status['Action'],
        enabled: expected_status['Enabled'] == 'true'
      )
    end
  end
end
