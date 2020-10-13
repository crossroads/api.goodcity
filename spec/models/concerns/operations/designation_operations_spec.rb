require 'rails_helper'

context DesignationOperations do
  let(:package) { create(:package, :with_inventory_record, received_quantity: 5) }
  let(:uninventorized_package) { create(:package) }
  let(:order) { create(:order, :with_state_processing) }
  let(:other_order) { create(:order, :with_state_processing) }
  let(:third_order) { create(:order, :with_state_processing) }
  let(:closed_order) { create(:order, :with_state_closed)}
  let(:dispatching_order) { create(:order, :with_state_dispatching) }
  let(:inactive_order) { create(:order, :with_state_draft) }
  let(:subject) {
    Class.new { include DesignationOperations }
  }

  before do
    allow(Stockit::OrdersPackageSync).to receive(:create)
    allow(Stockit::OrdersPackageSync).to receive(:update)
  end

  before(:each) do
    expect(PackagesInventory::Computer.package_quantity(package)).to eq(5)
    expect(PackagesInventory.count).to eq(1)
  end

  def designate(quantity, pkg: package, to_order: order, shipping_number: nil)
    subject::Operations.designate(pkg,
      quantity: quantity,
      to_order: to_order,
      shipping_number: shipping_number
    )
  end

  describe 'Designation operation' do

    it 'designates the entire quantity successfully' do
      expect(Stockit::OrdersPackageSync).to receive(:create).once
      expect { designate(5, shipping_number: 9999) }.to change(OrdersPackage, :count).by(1)
      expect(OrdersPackage.last.quantity).to eq(5)
      expect(OrdersPackage.last.state).to eq('designated')
      expect(OrdersPackage.last.shipping_number).to eq(9999)
    end

    it 'designates a partial quantity successfully' do
      expect(Stockit::OrdersPackageSync).to receive(:create).once
      expect { designate(3) }.to change(OrdersPackage, :count).by(1)
      expect(OrdersPackage.last.quantity).to eq(3)
      expect(OrdersPackage.last.state).to eq('designated')
    end

    describe 'when already designated' do
      it 'updates the existing orders_packages' do
        expect(Stockit::OrdersPackageSync).to receive(:create).once
        expect(Stockit::OrdersPackageSync).to receive(:update).once

        ord_pkg = designate(4)
        expect { designate(5) }.to change { OrdersPackage.find(ord_pkg.id).quantity }.from(4).to(5)
      end

      it 'marks the orders_package as dispatched if the quantity is lowered to match the already dispatched quantity' do
        expect(Stockit::OrdersPackageSync).to receive(:create)
        expect(Stockit::OrdersPackageSync).to receive(:update).twice

        ord_pkg = designate(4, to_order: dispatching_order)
        OrdersPackage::Operations.dispatch(ord_pkg, quantity: 3, from_location: package.locations.first)
        expect { designate(3, to_order: dispatching_order) }.to change {
          OrdersPackage.find(ord_pkg.id).state
        }.from("designated").to("dispatched")
      end

      it 'marks the orders_package as dispatched if the remaining undispatched quantity is dispatched' do
        allow(Stockit::OrdersPackageSync).to receive(:create)
        allow(Stockit::OrdersPackageSync).to receive(:update)

        ord_pkg = designate(4, to_order: dispatching_order)
        expect(ord_pkg.quantity).to eq(4)
        expect(ord_pkg.dispatched_quantity).to eq(0)

        OrdersPackage::Operations.dispatch(ord_pkg, quantity: 2, from_location: package.locations.first)

        ord_pkg.reload
        expect(ord_pkg.quantity).to eq(4)
        expect(ord_pkg.dispatched_quantity).to eq(2)

        expect { OrdersPackage::Operations.dispatch(ord_pkg, quantity: 2, from_location: package.locations.first) }.to change {
          ord_pkg.reload.state
        }.from("designated").to("dispatched")
      end

      it 'can designate the remaining quantity to another order' do
        expect(Stockit::OrdersPackageSync).to receive(:create).twice

        designate(4, to_order: order)
        expect { designate(1, to_order: other_order) }.to change(OrdersPackage, :count).by(1)
      end

      it 'fails to designate more than the remaining quantity to another order' do
        expect(Stockit::OrdersPackageSync).to receive(:create).once

        designate(4, to_order: order)
        expect { designate(2, to_order: other_order) }.to raise_error(Goodcity::InsufficientQuantityError).with_message("The selected quantity (2) is unavailable")
      end

      it 'fails to set a new quantity if more has already been dispatched' do
        expect(Stockit::OrdersPackageSync).to receive(:create).once
        expect(Stockit::OrdersPackageSync).to receive(:update).once

        orders_package = designate(4, to_order: dispatching_order)
        expect(orders_package.quantity).to eq(4)
        expect(
          PackagesInventory::Computer.dispatched_quantity(package: orders_package.package, orders_package: orders_package)
        ).to eq(0)

        OrdersPackage::Operations.dispatch(orders_package, quantity: 3, from_location: package.locations.first)

        expect(orders_package.reload.quantity).to eq(4)
        expect(
          PackagesInventory::Computer.dispatched_quantity(package: orders_package.package, orders_package: orders_package)
        ).to eq(3)

        expect {
          designate(2, to_order: dispatching_order)
        }.to raise_error(Goodcity::AlreadyDispatchedError).with_message('Some has been already dispatched, please undispatch and try again.')
      end
    end

    describe 'when previously cancelled' do
      it 'updates the state of the existing orders_package' do
        expect(Stockit::OrdersPackageSync).to receive(:create).once
        expect(Stockit::OrdersPackageSync).to receive(:update).twice

        ord_pkg = designate(4)
        ord_pkg.cancel
        expect { designate(5) }.to change { OrdersPackage.find(ord_pkg.id).state }.from('cancelled').to('designated')
      end
    end

    describe 'Validations' do
      it 'fails to designate more packages than are on hand' do
        expect { designate(6) }.to raise_error(Goodcity::InsufficientQuantityError).with_message('The selected quantity (6) is unavailable')
      end

      it 'fails to designate negative quantities' do
        expect { designate(-1) }.to raise_error(Goodcity::InvalidQuantityError).with_message('Invalid quantity (-1)')
      end

      it 'fails to designate to an inactive order' do
        expect { designate(5, to_order: inactive_order) }.to raise_error(Goodcity::InactiveOrderError).with_message("Operation forbidden, order #{inactive_order.code} is inactive")
      end

      it 'fails to designate an uninventorized package' do
        expect { designate(5, pkg: uninventorized_package) }.to raise_error(Goodcity::NotInventorizedError).with_message("Cannot operate on uninventorized packages")
      end
    end
  end

  describe 'Redesignation operation' do
    let(:orders_package) { OrdersPackage.first }

    before do
      designate(5);
      expect(OrdersPackage.count).to eq(1)
      touch(orders_package)
    end

    context 'of an active orders_package' do
      it 'fails to redesignate a non-cancelled orders_package' do
        expect {
          subject::Operations.redesignate(orders_package, to_order: other_order)
        }.to raise_error(Goodcity::ExpectedStateError).with_message('The following action can only be done on a cancelled OrdersPackage')
      end
    end

    context 'of a cancelled orders_package' do
      before { orders_package.update(state: 'cancelled') }

      it 'redesignates sucessfully to another order' do
        expect {
          subject::Operations.redesignate(orders_package, to_order: other_order)
        }.not_to raise_error

        expect(orders_package.reload.order).to eq(other_order)
        expect(orders_package.reload.state).to eq('designated')
      end

      context 'with 0 quantity' do
        before { orders_package.update(quantity: 0) }

        it 'fails' do
          expect {
            subject::Operations.redesignate(orders_package, to_order: other_order)
          }.to raise_error(Goodcity::InvalidQuantityError)
        end
      end

      it 'fails if the package is already designated by some other Orders package' do
        designate(5, to_order: other_order)
        expect {
          subject::Operations.redesignate(orders_package, to_order: other_order)
        }.to raise_error(Goodcity::AlreadyDesignatedError)
      end

      it 'fails if the package doesnt have sufficient available quantity' do
        designate(5, to_order: third_order)
        expect(PackagesInventory::Computer.available_quantity_of(package.id)).to eq(0)
        expect {
          subject::Operations.redesignate(orders_package, to_order: other_order)
        }.to raise_error(Goodcity::InsufficientQuantityError).with_message('The selected quantity (5) is unavailable')
      end

      it 'fails if the order is not active (cancelled/closed)' do
        other_order.cancel
        expect {
          subject::Operations.redesignate(orders_package, to_order: other_order)
        }.to raise_error(Goodcity::InactiveOrderError)
      end
    end
  end
end
