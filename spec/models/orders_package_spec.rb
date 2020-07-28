require 'rails_helper'

RSpec.describe OrdersPackage, type: :model do
  before do
    User.current_user = create(:user)
    allow(Stockit::OrdersPackageSync).to receive(:create)
    allow(Stockit::OrdersPackageSync).to receive(:update)
  end

  describe "Associations" do
    it { is_expected.to belong_to :order }
    it { is_expected.to belong_to :package }
    it { is_expected.to belong_to(:updated_by).class_name('User') }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:package_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:order_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:quantity).of_type(:integer)}
    it{ is_expected.to have_db_column(:dispatched_quantity).of_type(:integer)}
    it{ is_expected.to have_db_column(:state).of_type(:string)}
    it{ is_expected.to have_db_column(:sent_on).of_type(:datetime)}
  end

  describe "Validations" do
    context 'validates quantity' do
      it { is_expected.to_not allow_value(-1).for(:quantity) }
      it { is_expected.to allow_value(rand(4)).for(:quantity) }

      context 'based on availability' do
        let(:pkg) { create :package, :with_inventory_record, received_quantity: 1 }
        let(:dispatched_orders_package) { create :orders_package, :with_inventory_record, state: 'dispatched', package: pkg, quantity: 1 }

        before do
          expect { touch(dispatched_orders_package) }.to change {
            pkg.reload.available_quantity
          }.from(1).to(0)
          expect(OrdersPackage.count).to eq(1)
        end

        it 'fails to create a designated orders_package without availability' do
          expect {
            create(:orders_package, :with_inventory_record, state: 'designated', package: pkg, quantity: 1)
          }.to raise_error(Goodcity::InsufficientQuantityError)
          expect(OrdersPackage.count).to eq(1)
        end

        it 'fails to create a dispatched orders_package without availability' do
          expect {
            create(:orders_package, :with_inventory_record, state: 'dispatched', package: pkg, quantity: 1)
          }.to raise_error(Goodcity::InsufficientQuantityError)
          expect(OrdersPackage.count).to eq(1)
        end

        it 'succeeds to create a cancelled orders_package without availability' do
          expect {
            create(:orders_package, :with_inventory_record, state: 'cancelled', package: pkg, quantity: 1)
          }.not_to raise_error
          expect(OrdersPackage.count).to eq(2)
        end

        it 'fails to update the state from cancelled to designated without availability' do
          orders_package = create(:orders_package, :with_inventory_record, state: 'cancelled', package: pkg, quantity: 1)
          expect(OrdersPackage.count).to eq(2)
          expect {
            orders_package.update(state: 'designated')
          }.to raise_error(Goodcity::InsufficientQuantityError)
        end

        it 'fails to update the state from cancelled to dispatched without availability' do
          orders_package = create(:orders_package, :with_inventory_record, state: 'cancelled', package: pkg, quantity: 1)
          expect(OrdersPackage.count).to eq(2)
          expect {
            orders_package.update(state: 'dispatched')
          }.to raise_error(Goodcity::InsufficientQuantityError)
        end

        it 'succeeds to update the state of an existing record' do
          expect {
            dispatched_orders_package.update(state: 'designated')
          }.not_to raise_error
        end
      end
    end
  end

  describe "update_state_to_designated" do
    it "set state='designated'"do
      @orders_package = create :orders_package, :with_inventory_record, :with_state_requested
      @orders_package.update_state_to_designated
      expect(@orders_package.state).to match("designated")
    end
  end

  describe "state" do
    let!(:orders_package) { create :orders_package, state: 'requested' }

    describe '#reject' do
      it 'changes state from requested to cancelled' do
        expect{
          orders_package.reject
        }.to change(orders_package, :state).to('cancelled')
      end
    end

    describe '#designate' do
      it 'changes state from requested to designated' do
        expect{
          orders_package.designate
        }.to change(orders_package, :state).to('designated')
      end
    end
  end

  describe "#for_order" do
    it "return orders_package according to order_id" do
      order = create :order
      create_list(:orders_package, 2, order_id: order.id)
      create_list(:orders_package, 2)
      orders_packages = OrdersPackage.for_order(order.id)
      expect(orders_packages.size ).to eq(2)
      expect(orders_packages.pluck(:order_id)).to eq([order.id, order.id])
    end
  end

  describe '#dispatch_orders_package' do
    before(:all) do
      Timecop.freeze(Time.current)
    end

    let!(:orders_package) { create :orders_package, state: 'designated', quantity: 1 }
    let!(:dispatched_location) { create :location,  building: "Dispatched" }

    it "sets today's date for sent_on column" do
      todays_date = Date.today
      orders_package.dispatch_orders_package
      expect(orders_package.reload.sent_on.to_date).to eq todays_date
    end

    it 'updates state to dispatched' do
      expect{
        orders_package.dispatch_orders_package
        }.to change(orders_package, :state).to eq 'dispatched'
    end

    after(:all) do
      Timecop.freeze(Time.current)
    end
  end

  describe '#undispatch_orders_package' do
    before(:all) do
      Timecop.freeze(Time.current)
    end

    let!(:orders_package) { create :orders_package, :with_state_requested, sent_on: Date.today }

    it 'sets state as designated' do
      expect{
        orders_package.undispatch_orders_package
      }.to change(orders_package, :state).to('designated')
    end

    it 'sent_on to nil' do
      expect{
        orders_package.undispatch_orders_package
      }.to change(orders_package, :sent_on).to(nil)
    end

    after(:all) do
      Timecop.return
    end
  end

  describe '#delete_unwanted_cancelled_packages' do
    before do
      stub_request(:put, "http://www.example.com/api/v1/items/destroy").
        with(:body => "{\"gc_orders_package_id\":#{orders_package.id}}",
          :headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type'=>'application/json',
          'Token'=>'jchahjfsjfvacterr6e87dfbdsbqvh3v4brrb',
          'User-Agent'=>'Ruby'}).
         to_return(:status => 200, :body => "", :headers => {})
    end

    let!(:order) { create :order }
    let!(:orders_package) { create :orders_package, :with_state_cancelled, order: order }

    it 'deletes unwanted records with provided order id and state cancelled' do
      expect{
        orders_package.delete_unwanted_cancelled_packages(order.id)
      }.to change(OrdersPackage, :count).by(-1)
    end
  end

  describe 'Computing quantities' do
    context 'when dispatching' do
      let(:package) { create :package, :with_inventory_record, received_quantity: 5 }
      let(:order) { create :order, :with_designated_orders_packages, :with_state_dispatching }
      let(:orders_package) { create :orders_package, :with_state_designated, order: order, package: package }
      let(:location) { package.locations.first }

      before { initialize_inventory(package) }

      it 'updates the dispatched_quantity column' do
        expect(PackagesInventory::Computer.package_quantity(package)).to eq(5)
        expect {
          OrdersPackage::Operations.dispatch(orders_package, quantity: 2, from_location: location)
        }.to change { orders_package.reload.dispatched_quantity }.from(0).to(2)
      end
    end

    context 'when undispatching' do
      let(:package) { create :package, :with_inventory_record, received_quantity: 5 }
      let(:order) { create :order, :with_designated_orders_packages, :with_state_dispatching }
      let(:orders_package) { create :orders_package, :with_state_designated, order: order, package: package }
      let(:location) { package.locations.first }

      before do
        initialize_inventory(package)
        OrdersPackage::Operations.dispatch(orders_package, quantity: 2, from_location: location)
      end

      it 'updates the dispatched_quantity column' do
        expect(PackagesInventory::Computer.package_quantity(package)).to eq(3)
        expect {
          OrdersPackage::Operations.undispatch(orders_package, quantity: 1, to_location: location)
        }.to change { orders_package.reload.dispatched_quantity }.from(2).to(1)
      end
    end
  end

  describe 'Running actions' do
    context 'on a finished order' do
      let(:order) { create :order, :with_dispatched_orders_packages, :with_state_closed }
      let(:orders_package) { order.orders_packages.first }

      ['edit_quantity', 'undispatch', 'redesignate', 'cancel', 'dispatch'].each do |action|
        it "raises an error when the '#{action}' action is trigerred'" do
          expect { orders_package.exec_action action }.to raise_error(ArgumentError)
        end
      end
    end

    context 'on a designated package' do
      let(:order) { create :order, :with_designated_orders_packages, :with_state_processing }
      let(:orders_package) { order.orders_packages.first }

      it "calls :edit_quantity when the 'edit_quantity' action is trigerred" do
        expect(Package::Operations).to receive(:designate)
        orders_package.exec_action 'edit_quantity'
      end

      it "calls :dispatch when the 'dispatch' action is trigerred" do
        expect(OrdersPackage::Operations).to receive(:dispatch)
        orders_package.exec_action 'dispatch'
      end

      it "calls :cancel when the 'cancel' action is trigerred" do
        expect(orders_package).to receive(:cancel)
        orders_package.exec_action 'cancel'
      end

      ['undispatch', 'redesignate'].each do |action|
        it "raises an error when the '#{action}' action is trigerred'" do
          expect { orders_package.exec_action action }.to raise_error(ArgumentError)
        end
      end
    end

    context 'on a dispatched package' do
      let(:order) { create :order, :with_dispatched_orders_packages, :with_state_dispatching }
      let(:orders_package) { order.orders_packages.first }

      it "calls :undispatch_orders_package when the 'undispatch' action is trigerred" do
        expect(OrdersPackage::Operations).to receive(:undispatch)
        orders_package.exec_action 'undispatch'
      end

      ['edit_quantity', 'redesignate', 'cancel', 'dispatch'].each do |action|
        it "raises an error when the '#{action}' action is trigerred'" do
          expect { orders_package.exec_action action }.to raise_error(ArgumentError)
        end
      end
    end

    context 'on a cancelled package' do
      let(:order) { create :order, :with_cancelled_orders_packages, :with_state_dispatching }
      let(:orders_package) { order.orders_packages.first }

      it "calls Operations::redesignate when the 'redesignate' action is trigerred" do
        expect(OrdersPackage::Operations).to receive(:redesignate)
        orders_package.exec_action 'redesignate'
      end

      ['edit_quantity', 'undispatch', 'cancel', 'dispatch'].each do |action|
        it "raises an error when the '#{action}' action is trigerred'" do
          expect { orders_package.exec_action action }.to raise_error(ArgumentError)
        end
      end
    end
  end
end
