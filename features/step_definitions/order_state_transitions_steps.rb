Given(/^I have an order of state "([^"]*)"/) do |state|
  @order = create :order, state: state
end

And(/^It has an orders_package of state "([^"]*)"/) do |state|
  package = create :package, received_quantity: 5
  create :packages_inventory, package: package, quantity: package.received_quantity, action: 'inventory'

  @orders_package = create :orders_package, order: @order, package_id: package.id, state: state
end

When(/^I dispatch the orders_package/) do
  OrdersPackage::Operations.dispatch(@orders_package, quantity: @orders_package.quantity, from_location: @orders_package.package.locations.first)
end

Then(/^Dispatching the orders_package should "([^"]*)"/) do |result|
  expect_fail     = (result == "fail")

  expect {
    OrdersPackage::Actions::DISPATCH.run(@orders_package,
      location_id:    @orders_package.package.locations.first.id,
      quantity:       @orders_package.package.received_quantity,
    )
  }.to (
    expect_fail ? raise_error(Goodcity::OperationsError) : change(PackagesInventory, :count).by(1)
  )
end

Then(/^The order transitions to the "([^"]*)" state/) do |expected_state|
  expect(@order.reload.state).to eq(expected_state)
end

Then(/^Applying the "([^"]*)" transition to the order "([^"]*)"/) do |transition, expected_result|
  should_fail = expected_result.match(/^fail/)

  current_state   = @order.state
  expected_state  = transition

  expect {
    @order.fire_state_event(transition)
  }.to (
    should_fail ?
      raise_error(Goodcity::InvalidStateError) :
      change { @order.reload.state }.from(current_state).to(expected_state)
  )
end
