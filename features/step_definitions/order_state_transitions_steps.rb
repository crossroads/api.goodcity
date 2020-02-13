Given(/^I have an order of state "([^"]*)"/) do |state|
  @order = create :order, state: state
end

And(/^It has a orders_package of state "([^"]*)"/) do |state|
  package = create :package, received_quantity: 5
  create :packages_inventory, package: package, quantity: package.received_quantity, action: 'inventory'

  @orders_package = create :orders_package, order: @order, package_id: package.id, state: state
end

Then(/Dispatching the orders_package should "([^"]*)"/) do |result|
  expect_fail     = (result == "fail")

  expect {
    OrdersPackage::Actions::DISPATCH.run(@orders_package,
      location_id:    @orders_package.package.locations.first.id,
      quantity:       @orders_package.package.received_quantity,
    )
  }.to (
    expect_fail ?
      raise_error(Goodcity::OperationsError)
      : change(PackagesInventory, :count).by(1)
  )
end
