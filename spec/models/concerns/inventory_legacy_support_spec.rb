require 'rails_helper'

describe InventoryLegacySupport do
  let(:dispatch_location) { create(:location, :dispatched) }
  let(:location) { create(:location) }
  let(:other_location) { create(:location) }
  let(:user) { create(:user) }
  let(:package) { create(:package) }
  let(:other_package) { create(:package) }
  let(:packages_location) { create(:packages_location, quantity: quantity, location: location, package: package) }
  let(:packages_location_dispatch) { create(:packages_location, quantity: quantity, location: dispatch_location, package: package) }
  let(:computer) { PackagesInventory::Computer }

  before do
    touch(dispatch_location)
    User.current_user = user
  end

  after(:each) do
    # After each test, we assert that the two tables are in sync

    # 1. The total number of packages is the same on the two tables
    expect(computer.total_quantity).to eq(
      PackagesLocation.all.sum(:quantity)
    )

    # 2. Each package has the same quantity on both tables
    Package.all.each do |pkg|
      expect(computer.package_quantity(pkg)).to eq(
        PackagesLocation
          .where('package_id = (?)', pkg.id)
          .sum(:quantity)
      )
    end
  end

  describe "Syncing PackagesLocation <-> PackagesInventory" do

    # [First direction]
    #
    # PackagesLocation ---> PackagesInventory
    #
    describe "Changing packages_locationns" do

      context "by creating a new PackagesLocation" do

        context "with positive quantity" do
          let(:quantity) { 13 }

          it "records an INCREMENTAL MOVE in the inventory" do
            expect {
              touch(packages_location)
            }.to change(PackagesInventory, :count).by(1)

            expect(PackagesInventory.count).to eq(1)
            record = PackagesInventory.first
            expect(record.quantity).to eq(quantity)
            expect(record.package).to eq(packages_location.package)
            expect(record.location).to eq(packages_location.location)
            expect(record.action).to eq('move')
            expect(record.source).to be_nil
          end
        end

        context "with zero quantity" do
          let(:quantity) { 0 }

          before { touch(packages_location) }

          it "doesn't record anything in the inventory" do
            expect { touch(packages_location) }.not_to change(PackagesInventory, :count)
          end
        end
      end

      context "by updating a PackagesLocation" do
        let(:quantity) { 13 }

        before { touch(packages_location) }

        context "by increasing it's quantity" do
          let(:added_quantity) { 10 }

          it "records an INCREMENTAL MOVE in the inventory" do
            expect {
              packages_location.increment!(:quantity, added_quantity)
            }.to change(PackagesInventory, :count).by(1)

            expect(PackagesInventory.count).to eq(2)
            record = PackagesInventory.last
            expect(record.quantity).to eq(added_quantity)
            expect(record.package).to eq(packages_location.package)
            expect(record.location).to eq(packages_location.location)
            expect(record.action).to eq('move')
            expect(record.source).to be_nil
          end

          it "accounts in the total computed quantity" do
            expect {
              packages_location.increment!(:quantity, added_quantity)
            }.to change {
              computer.package_quantity(package)
            }.by(added_quantity)

            expect(computer.package_quantity(package)).to eq(quantity + added_quantity)
          end
        end

        context "by decreasing it's quantity" do
          let(:removed_quantity) { 10 }

          it "records a DECREMENTAL MOVE in the inventory" do
            expect {
              packages_location.decrement!(:quantity, removed_quantity)
            }.to change(PackagesInventory, :count).by(1)

            expect(PackagesInventory.count).to eq(2)
            record = PackagesInventory.last
            expect(record.quantity).to eq(-1 * removed_quantity)
            expect(record.package).to eq(packages_location.package)
            expect(record.location).to eq(packages_location.location)
            expect(record.action).to eq('move')
            expect(record.source).to be_nil
          end

          it "accounts in the total computed quantity" do
            expect {
              packages_location.decrement!(:quantity, removed_quantity)
            }.to change {
              computer.package_quantity(package)
            }.by(-1 * removed_quantity)

            expect(computer.package_quantity(package)).to eq(quantity - removed_quantity)
          end
        end

        context "by zero-ing its quantity" do
          let!(:available_qty) {  packages_location.quantity }

          it "records an INCREMENTAL MOVE in the inventory" do
            expect {
              packages_location.update(quantity: 0)
            }.to change(PackagesInventory, :count).by(1)

            expect(PackagesInventory.count).to eq(2)
            record = PackagesInventory.last
            expect(record.quantity).to eq(-1 * available_qty)
            expect(record.package).to eq(packages_location.package)
            expect(record.location).to eq(packages_location.location)
            expect(record.action).to eq('move')
            expect(record.source).to be_nil
          end

          it "accounts in the total computed quantity" do
            expect {
              packages_location.update(quantity: 0)
            }.to change {
              computer.package_quantity(package)
            }.by(-1 * available_qty)

            expect(computer.package_quantity(package)).to eq(0)
          end
        end

        context "by changing the location" do
          it "records INCREMENTAL and DECREMENTAL MOVES in the inventory" do
            expect {
              packages_location.update(location_id: other_location.id)
            }.to change(PackagesInventory, :count).by(2)

            expect(PackagesInventory.count).to eq(3)

            first = PackagesInventory.all[1]
            expect(first.quantity).to eq(-1 * packages_location.quantity)
            expect(first.package).to eq(packages_location.package)
            expect(first.location).to eq(location)
            expect(first.action).to eq('move')
            expect(first.source).to be_nil

            second = PackagesInventory.all[2]
            expect(second.quantity).to eq(packages_location.quantity)
            expect(second.package).to eq(packages_location.package)
            expect(second.location).to eq(other_location)
            expect(second.action).to eq('move')
            expect(second.source).to be_nil
          end

          context "and zero-ing the quantity" do
            it "only records a DECREMENTAL MOVE" do
              available_qty = packages_location.quantity

              expect {
                packages_location.update(location_id: other_location.id, quantity: 0)
              }.to change(PackagesInventory, :count).by(1)

              expect(PackagesInventory.count).to eq(2)

              record = PackagesInventory.all[1]
              expect(record.quantity).to eq(-1 * available_qty)
              expect(record.package).to eq(packages_location.package)
              expect(record.location).to eq(location)
              expect(record.action).to eq('move')
              expect(record.source).to be_nil
            end
          end
        end

        context "by changing the package" do
          it "records DECREMENTAL and INCREMENTAL MOVES in the inventory" do
            expect {
              packages_location.update(package_id: other_package.id)
            }.to change(PackagesInventory, :count).by(2)

            expect(PackagesInventory.count).to eq(3)

            first = PackagesInventory.all[1]
            expect(first.quantity).to eq(-1 * packages_location.quantity)
            expect(first.package).to eq(package)
            expect(first.location).to eq(location)
            expect(first.action).to eq('move')
            expect(first.source).to be_nil

            second = PackagesInventory.all[2]
            expect(second.quantity).to eq(packages_location.quantity)
            expect(second.package).to eq(other_package)
            expect(second.location).to eq(location)
            expect(second.action).to eq('move')
            expect(second.source).to be_nil
          end

          context "and zero-ing the quantity" do
            it "only records a DECREMENTAL MOVE" do
              available_qty = packages_location.quantity

              expect {
                packages_location.update(package_id: other_package.id, quantity: 0)
              }.to change(PackagesInventory, :count).by(1)

              expect(PackagesInventory.count).to eq(2)

              record = PackagesInventory.all[1]
              expect(record.quantity).to eq(-1 * available_qty)
              expect(record.package).to eq(package)
              expect(record.location).to eq(location)
              expect(record.action).to eq('move')
              expect(record.source).to be_nil
            end
          end
        end

        context "by changing the package and the location" do
          it "records DECREMENTAL and INCREMENTAL MOVES in the inventory" do
            available_qty = packages_location.quantity

            expect {
              packages_location.update(package_id: other_package.id, location_id: other_location.id)
            }.to change(PackagesInventory, :count).by(2)

            expect(PackagesInventory.count).to eq(3)

            first = PackagesInventory.all[1]
            expect(first.quantity).to eq(-1 * available_qty)
            expect(first.package).to eq(package)
            expect(first.location).to eq(location)
            expect(first.action).to eq('move')
            expect(first.source).to be_nil

            second = PackagesInventory.all[2]
            expect(second.quantity).to eq(available_qty)
            expect(second.package).to eq(other_package)
            expect(second.location).to eq(other_location)
            expect(second.action).to eq('move')
            expect(second.source).to be_nil
          end

          context "and zero-ing the quantity" do
            it "only records a DECREMENTAL MOVE" do
              available_qty = packages_location.quantity

              expect {
                packages_location.update(package_id: other_package.id, location_id: other_location.id, quantity: 0)
              }.to change(PackagesInventory, :count).by(1)

              expect(PackagesInventory.count).to eq(2)

              record = PackagesInventory.all[1]
              expect(record.quantity).to eq(-1 * available_qty)
              expect(record.package).to eq(package)
              expect(record.location).to eq(location)
              expect(record.action).to eq('move')
              expect(record.source).to be_nil
            end
          end
        end
      end

      context "by deleting a PackagesLocation" do

        context "which had positive quantity" do
          let(:quantity) { 13 }

          before { touch(packages_location) }

          it "records a DECREMENTAL MOVE in the inventory" do
            expect {
              packages_location.destroy
            }.to change(PackagesInventory, :count).by(1)

            expect(PackagesInventory.count).to eq(2)
            record = PackagesInventory.last
            expect(record.quantity).to eq(-1 * quantity)
            expect(record.package).to eq(packages_location.package)
            expect(record.location).to eq(packages_location.location)
            expect(record.action).to eq('move')
            expect(record.source).to be_nil
          end

          it "accounts in the total computed quantity" do
            expect {
              packages_location.destroy
            }.to change {
              computer.package_quantity(package)
            }.by(-1 * quantity)

            expect(computer.package_quantity(package)).to eq(0)
          end
        end

        context "which had zero quantity" do
          let(:quantity) { 0 }

          before { touch(packages_location) }

          it "doesn't record anything in the inventory" do
            expect { packages_location.destroy }.not_to change(PackagesInventory, :count)
          end
        end
      end
    end

    # [Other direction]
    #
    # PackagesLocation <--- PackagesInventory
    #
    describe "Changing packages_inventories" do

      # --> INVENTORY
      context 'by registering an INVENTORY of a new package' do
        let(:quantity) { 3 }

        it 'creates the PackagesLocation with the correct quantity' do
          expect {
            create :packages_inventory, quantity: quantity, action: 'inventory', package: package, location: location
          }.to change(PackagesLocation, :count).by(1)

          expect(PackagesLocation.count).to eq(1)
          expect(PackagesLocation.first.quantity).to eq(quantity)
        end
      end

      # --> GAIN
      context 'by registering a GAIN' do
        let(:added_quantity) { 3 }

        context 'of an existing package' do
          let(:quantity) { 10 }

          before { touch(packages_location) }

          it 'increases the packages_location\'s quantity' do
            expect {
              create :packages_inventory, quantity: added_quantity, action: 'gain', package: package, location: location
            }.to change {
              packages_location.reload.quantity
            }.by(added_quantity)

            expect(packages_location.reload.quantity).to eq(quantity + added_quantity)
          end
        end

        context 'of a new package' do
          it 'creates the PackagesLocation with the correct quantity' do
            expect {
              create :packages_inventory, quantity: added_quantity, action: 'gain', package: package, location: location
            }.to change(PackagesLocation, :count).by(1)

            expect(PackagesLocation.count).to eq(1)
            expect(PackagesLocation.first.quantity).to eq(added_quantity)
          end
        end
      end

      # --> LOSS
      context 'by registering a LOSS' do
        let(:quantity) { 10 }

        before { touch(packages_location) }

        context 'of part of the quantity' do
          let(:removed_quantity) { 3 }

          it 'decreases the packages_location\'s quantity' do
            expect {
              create :packages_inventory, quantity: - removed_quantity, action: 'loss', package: package, location: location
            }.to change {
              packages_location.reload.quantity
            }.by(- removed_quantity)

            expect(packages_location.reload.quantity).to eq(quantity - removed_quantity)
          end
        end

        context 'of the entire quantity' do
          let(:removed_quantity) { quantity }

          it 'destroys the packages_location record' do
            expect {
              create :packages_inventory, quantity: - removed_quantity, action: 'loss', package: package, location: location
            }.to change(PackagesLocation, :count).by(-1)
          end
        end
      end

      # --> DISPATCH
      context 'by registering a DISPATCH' do
        let(:quantity) { 10 }

        before { touch(packages_location) }

        context 'of part of the quantity' do
          let(:removed_quantity) { 3 }

          it 'decreases the packages_location\'s quantity' do
            expect {
              create :packages_inventory, quantity: - removed_quantity, action: 'dispatch', package: package, location: location
            }.to change {
              packages_location.reload.quantity
            }.by(- removed_quantity)

            expect(packages_location.reload.quantity).to eq(quantity - removed_quantity)
          end

          it 'does not create any "Dispatched" packages_location\'s' do
            expect(PackagesLocation.where(package: package, location: dispatch_location).count).to eq(0)
            expect {
              create :packages_inventory, quantity: - removed_quantity, action: 'dispatch', package: package, location: location
            }.not_to change {
              PackagesLocation.where(package: package, location: dispatch_location).count
            }
          end
        end

        context 'of the entire quantity' do
          let(:removed_quantity) { quantity }

          it 'destroys the packages_location record' do
            expect {
              create :packages_inventory, quantity: - removed_quantity, action: 'dispatch', package: package, location: location
            }.to change {
              PackagesLocation.where(package: package, location: location).count
            }.by(-1)
          end

          it 'does not create any "Dispatched" packages_location\'s' do
            expect(PackagesLocation.where(package: package, location: dispatch_location).count).to eq(0)
            expect {
              create :packages_inventory, quantity: - removed_quantity, action: 'dispatch', package: package, location: location
            }.not_to change {
              PackagesLocation.where(package: package, location: dispatch_location).count
            }
          end
        end
      end

      # --> UNDISPATCH
      context 'by registering a UNDISPATCH' do
        let(:quantity) { 10 }

        before do
          touch(packages_location)
          create(:packages_inventory, quantity: -quantity, action: 'dispatch', package: package, location: location)
        end

        context 'of part of the quantity' do
          let(:restored_quantity) { 3 }

          it 'increases the packages_location\'s quantity' do
            expect {
              create :packages_inventory, quantity: restored_quantity, action: 'undispatch', package: package, location: location
            }.to change {
              PackagesLocation.find_by(package: package, location: location).try(:quantity) || 0
            }.from(0).to(restored_quantity)
          end

          it 'does nothing to any "Dispatched" packages_location\'s' do
            expect {
              create :packages_inventory, quantity: restored_quantity, action: 'undispatch', package: package, location: location
            }.not_to change {
              PackagesLocation.find_by(package: package, location: dispatch_location).try(:quantity) || 0
            }
          end
        end

        context 'of the entire quantity' do
          let(:restored_quantity) { quantity }

          it 'increases the packages_location\'s quantity' do
            expect {
              create :packages_inventory, quantity: restored_quantity, action: 'undispatch', package: package, location: location
            }.to change {
              PackagesLocation.find_by(package: package, location: location).try(:quantity) || 0
            }.from(0).to(restored_quantity)
          end

          it 'does nothing to any "Dispatched" packages_location\'s' do
            expect(PackagesLocation.find_by(package: package, location: dispatch_location)).to be_nil
            expect {
              create :packages_inventory, quantity: restored_quantity, action: 'undispatch', package: package, location: location
            }.not_to change {
              PackagesLocation.find_by(package: package, location: dispatch_location).try(:quantity) || 0
            }
          end
        end
      end
    end
  end
end
