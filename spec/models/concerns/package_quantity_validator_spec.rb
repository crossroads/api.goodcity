require 'rails_helper'

describe Offer do
  before(:each) do
    @package = create :package, :package_with_locations, quantity: 10, received_quantity: 10
    @package_quantity_validator = PackageQuantityValidator.new
    @error_message = ["cannot be greater than package quantity"]
  end

  it 'validate record when quantity is less than package received_quantity' do
    @package.packages_locations.first.update(quantity: 5)
    packages_location = PackagesLocation.new(quantity: 4, package: @package)
    expect(@package_quantity_validator.validate(packages_location)).to be_nil
  end

  it 'invalidate record when quantity is not less than package received_quantity' do
    @package.packages_locations.first.update(quantity: 5)
    packages_location = PackagesLocation.new(quantity: 10, package: @package)
    expect(@package_quantity_validator.validate(packages_location)).to eq(@error_message)
  end

  it 'validate record when quantity is less than package received_quantity and there is no record' do
    @package.packages_locations.destroy_all
    packages_location = PackagesLocation.new(quantity: 10, package: @package)
    expect(@package_quantity_validator.validate(packages_location)).to be_nil
  end

  it 'validate mutplile records only when quantity is less than package received_quantity ' do
    @order = create :order, :with_state_submitted
    (1..3).each do
      orders_package = OrdersPackage.new(quantity: 3, package: @package, order: @order)
      expect(@package_quantity_validator.validate(orders_package)).to be_nil
      @package.orders_packages << orders_package
    end
    orders_package = OrdersPackage.new(quantity: 3, package: @package, order: @order)
    expect(@package_quantity_validator.validate(orders_package)).to eq(@error_message)
  end
end
