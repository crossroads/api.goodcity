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

# We pass in quantity properties and state as a table
And(/^Their OrdersPackages have the following stock properties$/) do |qty_table|
  properties = qty_table.hashes
  @orders_packages_per_state = @order_states.reduce({}) do |dict, state|
    dict[state] = properties.map do |row|
      remaining_qty = row['Remaining Quantity'].to_i
      requested_qty = row['Requested Quantity'].to_i
      received_qty  = remaining_qty + requested_qty
      # Build orders_package with quantities
      create(
        :orders_package,
        state: row['State'],
        quantity: requested_qty,
        order: create(:order, state: state),
        package: create(
          :package,
          quantity: remaining_qty,
          received_quantity: received_qty
        )
      )
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