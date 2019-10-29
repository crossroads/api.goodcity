require 'rails_helper'

context OrderFulfilmentOperations do

  describe 'Undispatching an orders_package' do
    let(:dispatch_location) { create(:location, :dispatched) }
    let(:pkg) { create(:package, received_quantity: 30) }
    let(:location) { create(:location) }
    let!(:dispatch_pkg_loc) { create(:packages_location, package: pkg, location: dispatch_location, quantity: 30) }
    let!(:orders_package) { create(:orders_package, :with_state_dispatched, package: pkg, quantity: 30) }
    let(:subject) {
      Class.new { include OrderFulfilmentOperations }
    }

    before { subject::Operations::undispatch(orders_package, to_location: location) }

    it 'removes the dispatched packages_location record' do
      expect(PackagesLocation.find_by(id: dispatch_pkg_loc.id)).to be_nil
    end

    it 'adds the quantity from the dest location' do
      expect(
        PackagesLocation.find_by(location: location, package: pkg).quantity
      ).to eq(30)
    end

    it 'sets the state to designated' do
      expect(orders_package.reload.state).to eq('designated')
    end
  end

  describe 'Dispatching an orders_package' do
    let!(:dispatch_location) { create(:location, :dispatched) }
    let(:pkg) { create(:package, received_quantity: 30) }
    let(:location) { create(:location) }
    let!(:pkg_loc) { create(:packages_location, package: pkg, location: location, quantity: 30) }

    [
      :submitted,
      :draft,
      :processing,
      :closed,
      :cancelled
    ].each do |state|
      context "of a #{state} order" do
        let(:order) { create(:order, state: state) }
        let!(:orders_package) { create(:orders_package, :with_state_designated, order: order, package: pkg, quantity: 30) }

        it 'fails due to the order being unprocessed' do
          expect {
            subject::Operations::dispatch(orders_package)
          }.to raise_error(StandardError).with_message('Cannot dispatch packages from an unprocessed order')
        end
      end
    end

    [
      :awaiting_dispatch,
      :dispatching
    ].each do |state|
      let(:order) { create(:order, state: state) }
      let!(:orders_package) { create(:orders_package, :with_state_designated, order: order, package: pkg, quantity: 30) }

      context "of an #{state} order" do

        before { subject::Operations::dispatch(orders_package) }

        it 'moves the packages to the dispatch location' do
          dispatch_pkg_location = PackagesLocation.find_by(location: Location.dispatch_location, package: pkg)
          expect(dispatch_pkg_location.quantity).to eq(30)
        end

        it "removes the package's original location" do
          expect(PackagesLocation.find_by(id: pkg_loc.id)).to be_nil
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
  end
end
