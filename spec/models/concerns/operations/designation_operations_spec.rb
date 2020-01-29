require 'rails_helper'

context DesignationOperations do
  let(:package) { create(:package, :with_inventory_number) }
  let(:uninventorized_package) { create(:package) }
  let(:other_order) { create(:order, :with_state_processing) }
  let(:order) { create(:order, :with_state_processing) }
  let(:dispatching_order) { create(:order, :with_state_dispatching) }
  let(:inactive_order) { create(:order, :with_state_draft) }
  let(:subject) {
    Class.new { include DesignationOperations }
  }

  before(:each) do
    create(:packages_inventory, package: package, quantity: 5, action: 'inventory')
    expect(PackagesInventory::Computer.package_quantity(package)).to eq(5)
    expect(PackagesInventory.count).to eq(1)
  end

  describe 'Designation operation' do

    def designate(quantity, pkg: package, to_order: order)
      subject::Operations.designate(pkg, quantity: quantity, to_order: to_order)
    end

    it 'designates the entire quantity successfully' do
      expect(Stockit::OrdersPackageSync).to receive(:create).once
      expect { designate(5) }.to change(OrdersPackage, :count).by(1)
      expect(OrdersPackage.last.quantity).to eq(5)
      expect(OrdersPackage.last.state).to eq('designated')
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
        OrdersPackage::Operations.dispatch(ord_pkg, quantity: 2, from_location: package.locations.first)
        expect { OrdersPackage::Operations.dispatch(ord_pkg, quantity: 2, from_location: package.locations.first) }.to change {
          OrdersPackage.find(ord_pkg.id).state
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

        designate(4, to_order: dispatching_order)
        orders_package = dispatching_order.reload.orders_packages.first
        OrdersPackage::Operations.dispatch(orders_package, quantity: 3, from_location: package.locations.first)
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
end
