require 'rails_helper'

describe InventoryLegacySupport do
  let(:dispatch_location) { create(:location, :dispatched) }
  let(:location) { create(:location) }
  let(:other_location) { create(:location) }
  let(:user) { create(:user) }
  let(:package) { create(:package) }
  let(:other_package) { create(:package) }
  let(:packages_location) { PackagesLocation.find_by(package: package, location: location) }
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

  describe "Syncing PackagesInventory ---> PackagesLocation" do

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

          before do
            package.received_quantity = quantity
            initialize_inventory(package, location: location)
            expect(PackagesLocation.where(package: package, location: location).count).to eq(1)
            pl = PackagesLocation.find_by(package: package, location: location)
            expect(pl.quantity).to eq(quantity)
          end

          it 'increases the packages_location\'s quantity' do
            expect {
              create :packages_inventory, quantity: added_quantity, action: 'gain', package: package, location: location
            }.to change {
              packages_location.reload.quantity
            }.from(quantity).to(quantity + added_quantity)

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

        before do
          package.received_quantity = quantity
          initialize_inventory(package, location: location)
          expect(PackagesLocation.where(package: package, location: location).count).to eq(1)
          pl = PackagesLocation.find_by(package: package, location: location)
          expect(pl.quantity).to eq(quantity)
        end

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

        before do
          package.received_quantity = quantity
          initialize_inventory(package, location: location)
          expect(PackagesLocation.where(package: package, location: location).count).to eq(1)
          pl = PackagesLocation.find_by(package: package, location: location)
          expect(pl.quantity).to eq(quantity)
        end

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
          package.received_quantity = quantity
          initialize_inventory(package, location: location)
          create(:packages_inventory, quantity: -quantity, action: 'dispatch', package: package, location: location)
          expect(PackagesLocation.where(package: package, location: location).count).to eq(0)
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
