require 'rails_helper'

RSpec.describe OrdersPackage, type: :model do
  before { User.current_user = create(:user) }
  
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
     it 'validates quantity' do
      is_expected.to_not allow_value(-1).for(:quantity)
      is_expected.to allow_value(rand(4)).for(:quantity)
    end
  end

  describe "update_state_to_designated" do
    it "set state='designated'"do
      @orders_package = create :orders_package, :with_state_requested
      @orders_package.update_state_to_designated
      expect(@orders_package.state).to match("designated")
    end
  end

  describe "update_quantity" do
    it "Updates orders_packages quantity" do
      @orders_package = create :orders_package, :with_state_requested
      @orders_package.update_quantity
      expect(@orders_package.quantity).to match(@orders_package.package.quantity)
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

  describe '#update_designation' do
    let!(:orders_package) { create :orders_package }
    let!(:order) { create :order }

    it 'updates orders_package to provided order_id' do
      expect{
        orders_package.update_designation(order.id)
      }.to change(orders_package, :order_id).to(order.id)
    end
  end

  describe '#update_partially_designated_item' do
    let!(:package) { create :package, quantity: 10 }
    let!(:dispatched_location) { create :location,  building: "Dispatched" }

    it 'adds package quantity to orders_package quantity' do
      orders_package = build :orders_package, state: 'designated'
      total_qty = orders_package.quantity + package.quantity
      expect{
        orders_package.update_partially_designated_item(package)
      }.to change(orders_package, :quantity).to(total_qty)
    end

    it "updates state of orders_package to designated if state is 'cancelled'" do
      orders_package = build :orders_package, state: 'cancelled'
      expect{
        orders_package.update_partially_designated_item(package)
      }.to change(orders_package, :state).to('designated')
    end

    it 'do not update state of orders_package if state is designated' do
      orders_package = create :orders_package, state: 'designated', package: package
      existing_state = orders_package.state
      orders_package.update_partially_designated_item(package)
      expect(orders_package.reload.state).to eq existing_state
    end

    it 'do not update state of orders_package if state is received' do
      orders_package = create :orders_package, state: 'received'
      existing_state = orders_package.state
      orders_package.update_partially_designated_item(package)
      expect(orders_package.reload.state).to eq existing_state
    end

    it 'do not update state of orders_package if state is dispatched' do
      orders_package = create :orders_package, state: 'dispatched', package: package
      packages_location = create :packages_location, quantity: 2, location: dispatched_location, package: package
      existing_state = orders_package.state
      orders_package.reload.update_partially_designated_item(package)
      expect(orders_package.reload.state).to eq existing_state
    end
  end

  describe '#dispatch_orders_package' do
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

  end

  describe '.update_orders_package_state' do
    let!(:orders_package) { create :orders_package, state: 'designated', quantity: 3 }

    context 'when total_qty is zero' do
      total_qty = 0

      it 'updates quantity with total_qty' do
        expect{
          orders_package.update_orders_package_state(total_qty)
        }.to change(orders_package, :quantity).to(0)
      end

      it "updates state to 'cancelled'" do
        expect{
          orders_package.update_orders_package_state(total_qty)
        }.to change(orders_package, :state).to('cancelled')
      end
    end

    context 'when total_qty is not zero' do
      total_qty = 12

      it 'updates quantity with total_qty' do
        expect{
          orders_package.update_orders_package_state(total_qty)
        }.to change(orders_package, :quantity).to(total_qty)
      end

      it "updates state to 'designated'" do
        orders_package.update_orders_package_state(total_qty)
        expect(orders_package.reload.state).to eq 'designated'
      end
    end
  end

  describe '.add_partially_designated_item' do
    let!(:order) { create :order }
    let!(:package) { create :package, quantity: 20, received_quantity: 20 }

    it 'creates orders package with provided order_id, package_id, quantity' do
      package_params = { order_id: order.id, package_id: package.id, quantity: 10 }

      expect{
        OrdersPackage.add_partially_designated_item(package_params)
      }.to change(OrdersPackage, :count).by(1)
      expect(OrdersPackage.last.order_id).to eq(package_params[:order_id])
      expect(OrdersPackage.last.package_id).to eq(package_params[:package_id])
      expect(OrdersPackage.last.quantity).to eq(package_params[:quantity])
    end
  end

  describe '#undispatch_orders_package' do
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

  describe '#undesignate_partially_designated_item' do
    let!(:package) { create :package, quantity: 4, received_quantity: 10}
    let!(:order) { create :order }
    let!(:orders_package) { create :orders_package, order_id: order.id,
      package_id: package.id, quantity: 6, state: 'designated' }

    context 'when quantity to undesignate is not same as quantity of designation(orders_package)' do
      let!(:undesignate_package_params) {
        {
          "0" => { "orders_package_id" => "#{orders_package.id}",
            "package_id" => "#{package.id}",
            "quantity" => "3" }
        }
      }

      it 'reduces quantity to undesignate from its designation(orders_package) record' do
        new_quantity = orders_package.quantity - undesignate_package_params["0"]["quantity"].to_i
        OrdersPackage.undesignate_partially_designated_item(undesignate_package_params)
        expect(orders_package.reload.quantity).to eq new_quantity
      end

      it "updates state to 'designated' " do
        OrdersPackage.undesignate_partially_designated_item(undesignate_package_params)
        expect(orders_package.reload.state).to eq 'designated'
      end

      it 'adds undesignated quantity to its associated package' do
        new_quantity = package.quantity + undesignate_package_params["0"]["quantity"].to_i
        OrdersPackage.undesignate_partially_designated_item(undesignate_package_params)
        expect(package.reload.quantity).to eq new_quantity
      end
    end

    context 'when undesignate total quantity of designation(orders_package) and remaining quantity of designation is zero' do
      let!(:undesignate_package_params) {
        {
          "0" => { "orders_package_id" => "#{orders_package.id}",
            "package_id" => "#{package.id}",
            "quantity" => "#{orders_package.quantity}" }
        }
      }

      it 'reduces quantity to undesignate from its designation(orders_package) record' do
        new_quantity = orders_package.quantity - undesignate_package_params["0"]["quantity"].to_i
        OrdersPackage.undesignate_partially_designated_item(undesignate_package_params)
        expect(orders_package.reload.quantity).to eq new_quantity
      end

      it "updates state to 'cancelled' " do
        OrdersPackage.undesignate_partially_designated_item(undesignate_package_params)
        expect(orders_package.reload.state).to eq 'cancelled'
      end

      it 'adds undesignated quantity to its associated package' do
        new_quantity = package.quantity + undesignate_package_params["0"]["quantity"].to_i
        OrdersPackage.undesignate_partially_designated_item(undesignate_package_params)
        expect(package.reload.quantity).to eq new_quantity
      end
    end
  end

  describe 'Editing the quantity' do
    context 'of a dispatched orders_package' do
      let(:pkg) { create :package, received_quantity: 10  }
      let(:order) { create :order, :with_state_dispatching }
      let!(:orders_package) {
        create(:orders_package, :with_state_dispatched, order_id: order.id, package_id: pkg.id, quantity: 2)
      }

      it 'should fail to update the quantity' do
        expect(pkg.reload.in_hand_quantity).to eq(8)
        expect {
          orders_package.edit_quantity(1)
        }.to raise_error(StandardError).with_message('Quantity of already dispatched/cancelled items cannot be modified')
      end
    end

    context 'of a cancelled orders_package' do
      let(:pkg) { create :package, received_quantity: 10  }
      let(:order) { create :order, :with_state_dispatching }
      let!(:orders_package) {
        create(:orders_package, :with_state_cancelled, order_id: order.id, package_id: pkg.id, quantity: 2)
      }

      it 'should fail to update the quantity' do
        expect(pkg.reload.in_hand_quantity).to eq(10)
        expect {
          orders_package.edit_quantity(1)
        }.to raise_error(StandardError).with_message('Quantity of already dispatched/cancelled items cannot be modified')
      end
    end

    context 'of a designated orders_package' do
      let(:pkg) { create :package, received_quantity: 10  }
      let(:order) { create :order, :with_state_dispatching }
      let!(:orders_package) {
        create(:orders_package, :with_state_designated, order_id: order.id, package_id: pkg.id, quantity: 2)
      }

      it 'updates it properly' do
        expect(pkg.reload.in_hand_quantity).to eq(8)
        orders_package.edit_quantity(6)
        expect(orders_package.reload.quantity).to eq(6)
        expect(pkg.reload.in_hand_quantity).to eq(4)
      end

      it 'fails if it is requesting too much' do
        expect(pkg.reload.in_hand_quantity).to eq(8)
        expect {
          orders_package.edit_quantity(11)
        }.to raise_error(ArgumentError).with_message('We do not currently have the requested quantity in stock')
      end
    end
  end

  describe 'Computing quantities' do
    context 'when dispatching' do
      let(:order) { create :order, :with_designated_orders_packages, :with_state_dispatching }
      let(:orders_package) { order.orders_packages.first }
      let(:package) { orders_package.package }
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
      let(:order) { create :order, :with_designated_orders_packages, :with_state_dispatching }
      let(:orders_package) { order.orders_packages.first }
      let(:package) { orders_package.package }
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

      it "calls :update_designation when the 'redesignate' action is trigerred" do
        expect(orders_package).to receive(:update_designation)
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
