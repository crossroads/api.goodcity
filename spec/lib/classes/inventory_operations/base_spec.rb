require "rails_helper"

describe InventoryOperations::Base do
  let!(:dispatched_location) { create :location, :dispatched }

  describe "initialization for singletone package having associated dispatched location and orders_package" do
    let(:order) { create :order }
    let(:package) { create :package, received_quantity: 1 }
    let!(:orders_package) { create :orders_package, order: order, package: package }
    let!(:packages_location) { create :packages_location, package: package, location: dispatched_location }
    let(:base) { InventoryOperations::Base.new({ order_id: order.id, package_id: package.id, quantity: package.quantity }) }

    it { expect(base.instance_variable_get("@order_id")).to eql(order.id) }
    it { expect(base.instance_variable_get("@package_id")).to eql(package.id) }
    it { expect(base.instance_variable_get("@quantity")).to eql(package.quantity) }
    it { expect(base.instance_variable_get("@package")).to eql(package) }
    it { expect(base.instance_variable_get("@is_singletone_package")).to be_truthy }
    it { expect(base.instance_variable_get("@orders_package")).to eq(orders_package) }
    it { expect(base.instance_variable_get("@dispatched_packages_location")).to eq(packages_location) }
  end

  describe "initialization for multi quantity package without orders_package and packages_location" do
    let(:order) { create :order }
    let(:package) { create :package, received_quantity: 2 }
    let(:base) { InventoryOperations::Base.new({ order_id: order.id, package_id: package.id, quantity: package.quantity }) }

    it { expect(base.instance_variable_get("@order_id")).to eql(order.id) }
    it { expect(base.instance_variable_get("@package_id")).to eql(package.id) }
    it { expect(base.instance_variable_get("@quantity")).to eql(package.quantity) }
    it { expect(base.instance_variable_get("@package")).to eql(package) }
    it { expect(base.instance_variable_get("@is_singletone_package")).to be_falsy }
    it { expect(base.instance_variable_get("@orders_package").id).to be_nil }
    it { expect(base.instance_variable_get("@dispatched_packages_location")).to be_nil }
  end
end

