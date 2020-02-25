require 'rails_helper'

context OrderFulfilmentOperations do
  let(:inventory_length_before) { PackagesInventory.count }
  let(:dispatch_location) { create(:location, :dispatched) }

  subject {
    Class.new { include OrderFulfilmentOperations }
  }

  before { touch(dispatch_location) }

  after(:each) do
    # We should never have the dispatched location referenced in the inventory
    expect(PackagesInventory.pluck(:location_id).uniq).not_to include(dispatch_location.id)
  end

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
            subject::Operations::dispatch(orders_package, from_location: pkg.locations.first, quantity: orders_package.quantity)
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
            subject::Operations::dispatch(orders_package, from_location: pkg.locations.first, quantity: orders_package.quantity)
          end

          it 'does not move the packages to the dispatch location' do
            expect(PackagesLocation.find_by(location: Location.dispatch_location, package: pkg)).to be_nil
          end

          it "removes the package's original location" do
            expect(PackagesLocation.find_by(id: pkg_loc.id)).to be_nil
          end

          it 'records a DISPATCH action in the inventory' do
            expect(inventory_rows_added).to eq(1)

            row = PackagesInventory.last
            expect(row.action).to eq('dispatch')
            expect(row.location).to eq(location)
            expect(row.quantity).to eq(- orders_package.quantity)
          end

          it "sets the sent_on field" do
            expect(PackagesLocation.find_by(id: pkg_loc.id)).to be_nil
            expect(orders_package.reload.sent_on).not_to be_nil
          end

          it "sets the stockit_sent_on field on the package" do
            expect(PackagesLocation.find_by(id: pkg_loc.id)).to be_nil
            expect(orders_package.package.reload.stockit_sent_on).not_to be_nil
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

          it 'does not move anything to the dispatch location' do
            expect(PackagesLocation.find_by(location: Location.dispatch_location, package: pkg)).to be_nil
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
    let(:dispatch_location) { create(:location, :dispatched) }
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

      it 'doesnt have any side effects on any dispatched packages_location' do
        expect(PackagesLocation.find_by(package: pkg, location: dispatch_location)).to be_nil
        expect { undispatch_full }.not_to change {
          PackagesLocation.find_by(package: pkg, location: dispatch_location)
        }
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

      it 'doesnt have any side effects on any dispatched packages_location' do
        expect(PackagesLocation.find_by(package: pkg, location: dispatch_location)).to be_nil
        expect { undispatch_partial }.not_to change {
          PackagesLocation.find_by(package: pkg, location: dispatch_location)
        }
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
end
