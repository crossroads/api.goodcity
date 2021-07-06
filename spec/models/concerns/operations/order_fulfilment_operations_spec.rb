require 'rails_helper'

context OrderFulfilmentOperations do
  let(:inventory_length_before) { PackagesInventory.count }

  subject {
    Class.new { include OrderFulfilmentOperations }
  }

  def inventory_rows_added
    PackagesInventory.count - inventory_length_before
  end

  describe 'Dispatching an orders_package' do
    let(:pkg) { create(:package, received_quantity: 30) }
    let(:location) { create(:location) }
    let(:pkg_loc) { pkg.packages_locations.first }

    before do
      initialize_inventory(pkg, location: location)
      touch(pkg_loc)
    end

    [
      :submitted,
      :draft,
      :processing,
      :closed,
      :cancelled
    ].each do |state|
      context "of a \"#{state} order\"" do
        let(:order) { create(:order, state: state) }
        let!(:orders_package) { create(:orders_package, :with_state_designated, order: order, package: pkg, quantity: 30) }

        it 'fails due to the order being unprocessed' do
          expect {
            subject::Operations::dispatch(orders_package, from_location: location, quantity: orders_package.quantity)
          }.to raise_error(
            Goodcity::OperationsError
          ).with_message('Cannot dispatch packages from an unprocessed order')
        end
      end
    end

    [
      :awaiting_dispatch,
      :dispatching
    ].each do |state|

      context "entire quantity" do
        context "of a \"#{state} order\"" do
          let(:order) { create(:order, state: state) }
          let(:orders_package) { create(:orders_package, :with_state_designated, order: order, package: pkg, quantity: 30) }

          before do
            touch(orders_package)
            touch(inventory_length_before)
          end

          def apply_dispatch!
            subject::Operations::dispatch(orders_package, from_location: location, quantity: orders_package.quantity)
          end

          it "removes the package's original location" do
            apply_dispatch!
            expect(PackagesLocation.find_by(id: pkg_loc.id)).to be_nil
          end

          it 'records a DISPATCH action in the inventory' do
            apply_dispatch!
            expect(inventory_rows_added).to eq(1)

            row = PackagesInventory.last
            expect(row.action).to eq('dispatch')
            expect(row.location).to eq(location)
            expect(row.quantity).to eq(- orders_package.quantity)
          end

          it "sets the sent_on field" do
            apply_dispatch!
            expect(PackagesLocation.find_by(id: pkg_loc.id)).to be_nil
            expect(orders_package.reload.sent_on).not_to be_nil
          end

          context 'with multiple locations' do
            let(:other_location) { create(:location) }

            before { Package::Operations::register_gain(pkg, quantity: 10, location: other_location) }

            it 'does not affect other locations' do
              expect(PackagesInventory::Computer.package_quantity(pkg, location: location)).to eq(30)
              expect(PackagesInventory::Computer.package_quantity(pkg, location: other_location)).to eq(10)
              expect(pkg.reload.packages_locations.count).to eq(2)

              apply_dispatch!

              expect(PackagesInventory::Computer.package_quantity(pkg, location: location)).to eq(0)
              expect(PackagesInventory::Computer.package_quantity(pkg, location: other_location)).to eq(10)
              expect(pkg.reload.packages_locations.count).to eq(1)
            end
          end
        end
      end

      context "exceed quantity than designated-quantity" do
        context "of a \"#{state} order\"" do
          let(:order) { create(:order, state: state) }
          let(:orders_package) { create(:orders_package, :with_state_designated, order: order, package: pkg, quantity: 30) }

          before do
            touch(orders_package)
            touch(inventory_length_before)
          end

          it 'does not allow to dispatch more than designated-quantity' do
            expect {
              subject::Operations::dispatch(orders_package, from_location: pkg.locations.first, quantity: orders_package.quantity + 10)
            }.to raise_error(
              Goodcity::ActionNotAllowedError
            ).with_message("You cannot dispatch more than were ordered.")
          end
        end
      end

      context "partial quantity" do
        context "of a \"#{state} order\"" do
          let(:dispatched_qty) { 3 }
          let(:order) { create(:order, state: state) }
          let(:orders_package) { create(:orders_package, :with_state_designated, order: order, package: pkg, quantity: 30) }
          let(:src_location) { pkg_loc.location }

          before do
            touch(src_location)
            touch(orders_package)
            touch(inventory_length_before)
            subject::Operations::dispatch(orders_package, from_location: src_location, quantity: dispatched_qty)
          end

          it "reduces quantity of the package's original location" do
            expect(pkg_loc.reload.quantity).to eq(27)
          end

          it 'records a DISPATCH action in the inventory' do
            expect(inventory_rows_added).to eq(1)

            row = PackagesInventory.last
            expect(row.action).to eq('dispatch')
            expect(row.location).to eq(location)
            expect(row.quantity).to eq(-3)
          end

          it "doesn't set the sent_on field" do
            expect(orders_package.reload.sent_on).to be_nil
          end

          it "sets the sent_on field only when the remaining quantity is dispatched as well" do
            expect(orders_package.reload.sent_on).to be_nil
            subject::Operations::dispatch(orders_package, from_location: src_location, quantity: 27)
            expect(orders_package.reload.sent_on).not_to be_nil
          end

          it "doesn't set the stockit_sent_on field on the package" do
            expect(orders_package.package.reload.stockit_sent_on).to be_nil
          end

          it "sets the stockit_sent_on field on the package only when the remaining quantity is dispatched as well" do
            expect(orders_package.package.reload.stockit_sent_on).to be_nil
            subject::Operations::dispatch(orders_package, from_location: src_location, quantity: 27)
            expect(orders_package.reload.sent_on).not_to be_nil
          end
        end
      end
    end

    describe 'Order state changes' do
      let(:dispatched_qty) { 3 }
      let(:scheduled_order) { create(:order, state: 'awaiting_dispatch') }
      let(:orders_package) { create(:orders_package, :with_state_designated, order: scheduled_order, package: pkg, quantity: 30) }

      it 'changes awaiting_dispatch orders to dispatching state' do
        expect {
          subject::Operations::dispatch(orders_package, from_location: location, quantity: 30)
        }.to change { scheduled_order.reload.state }.from("awaiting_dispatch").to("dispatching")
      end
    end
  end

  describe 'Undispatching an orders_package' do
    let(:location) { create(:location) }
    let(:pkg) { create(:package, received_quantity: 30) }
    let(:order) { create(:order, :with_state_dispatching) }
    let(:pkg_loc) { pkg.packages_locations.first }
    let(:src_location) { pkg_loc.location }
    let(:orders_package) { create(:orders_package, :with_state_designated, package: pkg, order: order, quantity: 30) }

    before do
      # Run the dispatch method to setup the test
      initialize_inventory(pkg, location: location)
      touch(pkg_loc)
      touch(src_location)
      touch(orders_package)
      subject::Operations::dispatch(orders_package, from_location: src_location, quantity: orders_package.quantity)
      expect(pkg.locations.length).to eq(0)
    end

    context 'entire quantity' do
      def undispatch_full
        subject::Operations::undispatch(orders_package, to_location: src_location, quantity: orders_package.quantity)
      end

      it 'records an UNDISPATCH action in the inventory' do
        expect { undispatch_full }.to change(PackagesInventory, :count).by(1)
        row = PackagesInventory.last
        expect(row.action).to eq('undispatch')
        expect(row.location).to eq(location)
        expect(row.quantity).to eq(orders_package.quantity)
      end

      it 'adds the quantity from the dest location' do
        expect { undispatch_full }.to change {
          PackagesLocation.find_by(location: location, package: pkg).try(:quantity) || 0
        }.from(0).to(30)
      end

      it 'sets the state to designated' do
        expect { undispatch_full }.to change {
          orders_package.reload.state
        }.from('dispatched').to('designated')
      end
    end

    context 'partial quantity' do
      def undispatch_partial
        subject::Operations::undispatch(orders_package, to_location: src_location, quantity: 5)
      end

      it 'records an UNDISPATCH action in the inventory' do
        expect { undispatch_partial }.to change(PackagesInventory, :count).by(1)
        row = PackagesInventory.last
        expect(row.action).to eq('undispatch')
        expect(row.location).to eq(location)
        expect(row.quantity).to eq(5)
      end

      it 'adds the quantity from the dest location' do
        expect { undispatch_partial }.to change {
          PackagesLocation.find_by(location: location, package: pkg).try(:quantity) || 0
        }.from(0).to(5)
      end

      it 'sets the state to designated' do
        expect { undispatch_partial }.to change {
          orders_package.reload.state
        }.from('dispatched').to('designated')
      end
    end
  end

  describe 'Bug recreation' do
    describe 'all PackagesLocation are deleted after any dispatch if received_quantity = 1' do
      let(:location) { create(:location) }
      let(:location2) { create(:location) }
      let(:package) { create(:package, :with_inventory_number, received_quantity: 1) }
      let(:order1) { create(:order, state: 'dispatching') }
      let(:order2) { create(:order, state: 'dispatching') }
      let(:order3) { create(:order, state: 'dispatching') }
      let(:order4) { create(:order, state: 'dispatching') }
      let(:orders_package1) { create(:orders_package, state: 'designated', package_id: package.id, order: order1, quantity: 128) }
      let(:orders_package2) { create(:orders_package, state: 'designated', package_id: package.id, order: order2, quantity: 48) }
      let(:orders_package3) { create(:orders_package, state: 'designated', package_id: package.id, order: order3, quantity: 92) }
      let(:orders_package4) { create(:orders_package, state: 'designated', package_id: package.id, order: order4, quantity: 82) }

      before do
        initialize_inventory(package, location: location)
        Package::Operations::register_gain(package, quantity: 379, location: location)
        Package::Operations.move(30, package, from: location, to: location2)
        touch(orders_package1, orders_package2, orders_package3, orders_package4)
        PackagesInventory::Computer.update_package_quantities!(package)
        expect(package.on_hand_quantity).to eq(380)
        expect(package.available_quantity).to eq(30)
        expect(package.designated_quantity).to eq(350)
        expect(package.dispatched_quantity).to eq(0)
      end

      it 'should dispatche correctly' do
        expect {
          OrdersPackage::Operations.dispatch(orders_package1.reload, quantity: 128, from_location: location)
        }.not_to raise_error
      end
    end
  end
end
