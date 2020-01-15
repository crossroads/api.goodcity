require "rails_helper"

RSpec.describe Api::V1::OrdersPackagesController, type: :controller do
  let(:orders_package) { create :orders_package }
  let(:order) { create :order, :with_state_draft }
  let(:user) { create(:user_with_token, :with_can_manage_orders_packages_permission, role_name: 'Reviewer') }
  let(:charity_user) { create(:user_with_token, :with_can_manage_orders_packages_permission, role_name: 'Charity') }
  let(:status) { response.status }
  subject { JSON.parse(response.body) }

  describe "GET packages for Item" do
   before { generate_and_set_token(user) }
    it "returns 200" do
      get :index
      expect(response.status).to eq(200)
    end

    it "return serialized orders_packages for provided order id" do
      order = create :order
      3.times{ create :orders_package, order_id: order.id }
      get :index, search_by_order_id: order.id
      expect( subject["orders_packages"].size ).to eq(3)
    end

    it 'returns designated and dispatched orders_packages' do
      expect(Stockit::OrdersPackageSync).to receive(:create).exactly(3).times
      order = create :order
      package = create :package, :with_inventory_number, quantity: 8, received_quantity: 8
      3.times{ create :orders_package, order_id: order.id, package_id: package.id, state: 'designated', quantity: 2 }
      get :index, search_by_package_id: package.id
      expect( subject["orders_packages"].size ).to eq(3)
    end

    it "return orders_packages of order_id mentioned in params" do
      order = create :order
      order2 = create :order
      create_list(:orders_package, 2, order_id: order.id)
      create_list(:orders_package, 2,order_id: order2.id)
      get :index, order_id: order.id
      expect( subject["orders_packages"].size ).to eq(2)
    end
  end

  describe "DELETE orders_package/1 " do
    before(:all) { WebMock.disable! }
    after(:all) { WebMock.enable! }

    before { generate_and_set_token(charity_user) }
    let(:orders_package) {create :orders_package, :with_state_requested, order_id: order.id}

    context 'if it is not last orders_package in order' do
      it "returns 200", :show_in_doc do
        delete :destroy, id: orders_package.id
        expect(response.status).to eq(200)
        expect(subject).to eq( {} )
      end

      it "should not delete order" do
        orders_package1 = create :orders_package, :with_state_requested, order_id: order.id
        delete :destroy, id: orders_package.id
        expect(Order.find_by_id(order.id)).to eq(order)
        expect(order.orders_packages.count).to eq(1)
      end
    end

    context 'if it is last orders_package in order' do
      it "delete order" do
        delete :destroy, id: orders_package.id
        expect(Order.find_by_id(order.id)).to be_nil
      end
    end
  end

  describe 'Executing actions' do
    #
    # Testing that each action does what it is intended to do
    #
    let!(:dispatch_location) { create(:location, :dispatched) }
    let(:json_record) { subject['orders_package'] }
    let(:error_text) { subject['errors'][0]['message'] }
    let(:new_state) { json_record['state'] }
    let(:current_state) { orders_package.state }

    context 'as a staff member' do
      before { generate_and_set_token(user) }

      describe 'with bad data' do
        let(:orders_package) {create :orders_package}

        it 'fails to execute an action that doesnt exist' do
          put :exec_action, id: orders_package.id, action_name: 'world_peace'
          expect(error_text).to eq('Action world_peace is not possible at the moment')
        end
      end

      describe 'Cancelling' do
        let(:order) { create :order, :with_state_submitted }
        let(:orders_package) {create :orders_package, :with_state_designated, order_id: order.id}

        it 'cancels the designation successfully' do
          expect(current_state).to eq('designated')

          put :exec_action, id: orders_package.id, action_name: 'cancel'
          expect(status).to eq(200)
          expect(orders_package.reload.state).to eq('cancelled')
          expect(new_state).to eq('cancelled')
        end
      end

      describe 'Redesignating' do
        let(:order) { create :order, :with_state_submitted }
        let(:order2) { create :order, :with_state_submitted }
        let(:orders_package) {create :orders_package, :with_state_cancelled, order_id: order.id}

        it 'redesignates the designation successfully' do
          expect(current_state).to eq('cancelled')

          put :exec_action, id: orders_package.id, action_name: 'redesignate', order_id: order2.id
          expect(status).to eq(200)
          expect(orders_package.reload.order_id).to eq(order2.id)
          expect(new_state).to eq('designated')
          expect(orders_package.reload.state).to eq('designated')
        end
      end

      describe 'Editing Quantity' do
        context 'of a designated orders_package' do
          let(:pkg) { create :package, :with_inventory_number, received_quantity: 10  }
          let(:order) { create :order, :with_state_dispatching }
          let(:orders_package) {
            create(:orders_package, :with_state_designated, order_id: order.id, package_id: pkg.id, quantity: 2)
          }

          before do
            expect(Stockit::OrdersPackageSync).to receive(:create)
            touch(orders_package)
            create(:packages_inventory, action: 'inventory', package: pkg, location: create(:location), quantity: pkg.received_quantity)
          end

          it 'updates correctly' do
            expect(Stockit::OrdersPackageSync).to receive(:update)
            expect(pkg.reload.in_hand_quantity).to eq(8)
            put :exec_action, id: orders_package.id, action_name: 'edit_quantity', quantity: 9
            expect(status).to eq(200)
            expect(pkg.reload.in_hand_quantity).to eq(1)
            expect(orders_package.reload.quantity).to eq(9)
          end

          it 'fails if requesting too much' do
            expect(pkg.reload.in_hand_quantity).to eq(8)
            put :exec_action, id: orders_package.id, action_name: 'edit_quantity', quantity: 11
            expect(status).to eq(422)
            expect(error_text).to eq('The selected quantity (11) is unavailable')
          end

          it 'fails if we dont pass a desired quantity' do
            put :exec_action, id: orders_package.id, action_name: 'edit_quantity'
            expect(status).to eq(422)
            expect(error_text).to match(/^Invalid quantity/)
          end
        end
      end

      describe 'Dispatching' do
        context 'items of a processed order' do
          let(:order) { create :order, :with_state_dispatching }
          let(:package) { create(:package, quantity: 10) }
          let(:orders_package) { create :orders_package, :with_state_designated, order_id: order.id, package: package, quantity: package.quantity }

          before do
            create(:packages_location, package: package, quantity: package.quantity)
          end

          it 'dispatches the packages successfully' do
            expect(current_state).to eq('designated')

            put :exec_action, id: orders_package.id, action_name: 'dispatch'

            expect(status).to eq(200)
            expect(new_state).to eq('dispatched')
            expect(orders_package.reload.state).to eq('dispatched')
            expect(package.reload.locations.length).to eq(0)
          end
        end

        context 'items of an unprocessed order' do
          let(:order) { create :order, :with_state_processing }
          let(:package) { create(:package, quantity: 10) }
          let(:orders_package) { create :orders_package, :with_state_designated, order: order, package: package, quantity: package.quantity }

          before do
            create(:packages_location, package: package, quantity: package.quantity)
          end

          it 'fails to dispatch the packages' do
            expect(current_state).to eq('designated')

            put :exec_action, id: orders_package.id, action_name: 'dispatch'

            expect(status).to eq(422)
            expect(error_text).to eq("Cannot dispatch packages from an unprocessed order")
          end
        end
      end

      describe 'Undispatching' do
        let!(:dispatch_location) { create(:location, :dispatched) }
        let(:location) { create(:location) }
        let(:order) { create :order, :with_state_dispatching }
        let(:quantity) { 10 }
        let(:package) { create(:package, quantity: 0) } # 0 quantity because it has been dispatched
        let(:orders_package) { create :orders_package, :with_state_dispatched, order: order, package: package, quantity: quantity }

        before do
          # Mock history
          build(:packages_inventory, action: 'inventory', package: package, quantity: quantity).sneaky(:save)
          build(:packages_inventory, action: 'dispatch', package: package, source: orders_package, quantity: -1 * quantity).sneaky(:save)
        end

        it 'fails to undispatch the packages if no valid location is provided' do
          expect(current_state).to eq('dispatched')

          put :exec_action, id: orders_package.id, action_name: 'undispatch'
          expect(status).to eq(422)
          expect(error_text).to match(/^Couldn't find Location with 'id'=/)
          expect(orders_package.reload.state).to eq('dispatched')
        end

        it 'undispatches the packages successfully' do
          expect(current_state).to eq('dispatched')

          put :exec_action, id: orders_package.id, action_name: 'undispatch', location_id: location.id
          expect(status).to eq(200)
          expect(new_state).to eq('designated')
          expect(orders_package.reload.state).to eq('designated')
          expect(package.reload.locations.length).to eq(1)
          expect(package.reload.locations.first).to eq(location)
        end
      end
    end
  end
end
