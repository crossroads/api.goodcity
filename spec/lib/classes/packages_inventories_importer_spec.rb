require "rails_helper"

describe PackagesInventoriesImporter do
  let(:quantities) { [1,2,3] }
  let(:on_hand_packages) {
    quantities.map { |qty|  create(:package, :package_with_locations, :with_inventory_number, quantity: qty, received_quantity: qty) }
  }
  let(:dispatched_packages) {
    quantities.map { |qty|  create(:package, :dispatched, :with_inventory_number, received_quantity: qty) }
  }
  let(:uninventorized_packages) {
    quantities.map { |qty|  create(:package, :package_with_locations, quantity: qty, received_quantity: qty) }
  }

  before(:each) do
    allow(Stockit::OrdersPackageSync).to receive(:create)
    touch(uninventorized_packages)
  end

  after(:each) do
    uninventorized_packages.each do |pkg|
      expect(PackagesInventory.where(package_id: pkg.id).count).to eq(0)
    end
  end

  def all_rows
    PackagesInventory.all
  end

  def inventory_rows
    PackagesInventory.where(action: 'inventory')
  end

  def dispatch_rows
    PackagesInventory.where(action: 'dispatch')
  end

  it 'should not run if records already exist' do
    create(:packages_inventory)
    expect { PackagesInventoriesImporter.import }.to raise_error(StandardError)
  end

  it 'should delete old records if run with the force flag' do
    old_record = create(:packages_inventory)
    expect { PackagesInventoriesImporter.import(force: true) }.not_to raise_error
    expect(PackagesInventory.find_by(id: old_record.id)).to be_nil
  end

  describe "For on hand packages" do

    before do
      touch(on_hand_packages)
      PackagesInventoriesImporter.import
    end

    it "creates only one 'inventory' action per package" do
      expect(all_rows.count).to eq(3)
      expect(inventory_rows.count).to eq(3)
      expect(dispatch_rows.count).to eq(0)
    end

    describe 'Verifying values' do
      it "inventories the package's received_quantity" do
        expect(inventory_rows.pluck(:quantity)).to eq(quantities)
      end

      it "inventories the package to its known location" do
        expected_locations = on_hand_packages.map { |p| p.packages_locations.first.location_id }
        expect(inventory_rows.pluck(:location_id)).to eq(expected_locations)
      end

      it "should compute the correct quantity in the inventory" do
        Package.inventorized.each do |p|
          expect(PackagesInventory::Computer.package_quantity(p)).to eq(p.quantity)
        end
      end
    end
  end

  describe "For dispatched packages" do

    before do
      touch(dispatched_packages)
      PackagesInventoriesImporter.import
    end

    it "creates one 'inventory' action per package" do
      expect(all_rows.count).to eq(6)
      expect(inventory_rows.count).to eq(3)
    end

    it "creates one 'dispatch' action per dispatched package" do
      expect(all_rows.count).to eq(6)
      expect(dispatch_rows.count).to eq(3)
    end

    describe 'Verifying values' do

      it "inventories the package's received_quantity" do
        expect(inventory_rows.pluck(:quantity)).to eq(quantities)
      end

      it "negates the quantity in the dispach row" do
        expect(dispatch_rows.pluck(:quantity)).to eq(quantities.map { |n| -n })
      end

      it "inventories the package to its type's default location" do
        expected_locations = dispatched_packages.map { |p| p.reload.package_type.location_id }
        expect(inventory_rows.pluck(:location_id)).to eq(expected_locations)
      end

      it "dispatches the package from its type's default location" do
        expected_locations = dispatched_packages.map { |p| p.reload.package_type.location_id }
        expect(dispatch_rows.pluck(:location_id)).to eq(expected_locations)
      end

      it "dispatch actions should point to an OrdersPackage record" do
        dispatch_rows.each do |row|
          expect(row.source_type).to eq('OrdersPackage')
          op = OrdersPackage.find(row.source_id)
          expect(op).not_to be_nil
          expect(op.package_id).to eq(row.package_id)
          expect(op.quantity).to eq(row.quantity.abs)
        end
      end

      it "should compute the correct quantity in the inventory" do
        Package.all.each do |p|
          expect(PackagesInventory::Computer.package_quantity(p)).to eq(0)
        end
        expect(PackagesInventory::Computer.total_quantity).to eq(0)
      end
    end
  end
end
