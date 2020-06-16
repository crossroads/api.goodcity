require "rails_helper"
require "goodcity/package_deduplicator"

describe Goodcity::PackageDeduplicator do
  let(:order) { create(:order) }
  let(:package_1) { create(:package, inventory_number: "999999", stockit_id: 42) }
  let(:package_2) { create(:package, inventory_number: "999999", stockit_id: 43) }
  let(:package_3) { create(:package, inventory_number: "999999", stockit_id: 44) }

  before do
    allow(Stockit::OrdersPackageSync).to receive(:create)

    initialize_inventory(package_1, package_2, package_3)
    package_1.update_column(:updated_at, Time.now)
    package_2.update_column(:updated_at, Time.now + 2.days)
    package_3.update_column(:updated_at, Time.now + 1.day)

    create(:orders_package, order: order, package: package_1, state: 'designated')
  end

  it "keeps the latest updated record" do
    expect {
      Goodcity::PackageDeduplicator.dedup(['999999'])
    }.to change(Package, :count).from(3).to(1)

    expect(Package.last.id).to eq(package_2.id)
  end

  it "deletes associated orders_packages" do
    expect {
      Goodcity::PackageDeduplicator.dedup(['999999'])
    }.to change(OrdersPackage, :count).from(1).to(0)
  end

  it "deletes associated packages_inventories" do
    expect {
      Goodcity::PackageDeduplicator.dedup(['999999'])
    }.to change(PackagesInventory, :count).from(3).to(1)

    expect(PackagesInventory.last.package_id).to eq(package_2.id)
  end

  it "deletes associated packages_locations" do
    expect {
      Goodcity::PackageDeduplicator.dedup(['999999'])
    }.to change(PackagesLocation, :count).from(3).to(1)

    expect(PackagesLocation.last.package_id).to eq(package_2.id)
  end
end
