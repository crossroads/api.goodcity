require "rails_helper"

RSpec.describe Api::V1::OrdersPackagesController, type: :controller do
  let(:orders_package) { create :orders_package }
  let(:order) { create :order, :with_state_draft }
  let(:user) { create(:user, :with_token, :with_can_manage_orders_packages_permission, role_name: 'Reviewer') }
  let(:charity_user) { create(:user, :with_token, :with_can_manage_orders_packages_permission, :charity) }
  let(:status) { response.status }
  subject { JSON.parse(response.body) }

  describe "GET packages for Item" do
    let(:order) { create :order }
    let(:order2) { create :order }
    let!(:orders_package1) { create :orders_package, order_id: order.id, state: 'designated' }
    let!(:orders_package2) { create :orders_package, order_id: order2.id, state: 'designated' }

    before {
      generate_and_set_token(user)
    }

    it "returns 200" do
      get :index
      expect(response.status).to eq(204)
    end

    it "return serialized orders_packages for provided order id" do
      order = create :order
      3.times { create :orders_package, order_id: order.id }
      get :index, params: { search_by_order_id: order.id }
      expect(subject["orders_packages"].size).to eq(3)
    end

    it 'returns designated and dispatched orders_packages' do
      order = create :order
      package = create :package, :with_inventory_record, received_quantity: 8
      3.times{ create :orders_package, order_id: order.id, package_id: package.id, state: 'designated', quantity: 2 }
      get :index, params: { search_by_package_id: package.id }
      expect( subject["orders_packages"].size ).to eq(3)
    end

    it "return orders_packages of order_id mentioned in params as per given sorting_column" do
      order_packages = Order.find(order.id).orders_packages
      get :index, params: { order_id: order.id, sorting_column: "packages.inventory_number"}
      expect( subject["orders_packages"].size ).to eq(1)
      expect(subject["orders_packages"][0]["order_id"]).to eq(order.id)
      expect(subject['meta']['orders_packages_count']).to eql(order_packages.size)
    end

    it "returns orders_packages for given order_id as per given states" do
      get :index, params: { order_id: order.id, state: "designated" }
      expect( subject["orders_packages"].size ).to eq(1)
      expect(subject["orders_packages"][0]["order_id"]).to eq(order.id)
    end

    it "returns orders_packages for given order_id as per searched text" do
      get :index, params: { order_id: order.id, sorting_column: "packages.inventory_number", searchText: orders_package1.package.inventory_number }
      expect( subject["orders_packages"].size ).to eq(1)
      expect(subject["orders_packages"][0]["id"]).to eq(orders_package1.id)
    end

    it "returns all orders_packages for given order_id for blank searchText" do
      get :index, params: { order_id: order.id, sorting_column: "packages.inventory_number", searchText: "" }
      expect( subject["orders_packages"].size ).to eq(1)
      expect(subject["orders_packages"][0]["id"]).to eq(orders_package1.id)
    end
  end

  describe "DELETE orders_package/1 " do
    before(:all) { WebMock.disable! }
    after(:all) { WebMock.enable! }

    before { generate_and_set_token(charity_user) }
    let(:orders_package) {create :orders_package, :with_state_requested, order_id: order.id}

    context 'if it is not last orders_package in order' do
      it "returns 200", :show_in_doc do
        delete :destroy, params: { id: orders_package.id }
        expect(response.status).to eq(200)
        expect(subject).to eq( {} )
      end

      it "should not delete order" do
        orders_package1 = create :orders_package, :with_state_requested, order_id: order.id
        delete :destroy, params: { id: orders_package.id }
        expect(Order.find_by_id(order.id)).to eq(order)
        expect(order.orders_packages.count).to eq(1)
      end
    end

    context 'if it is last orders_package in order' do
      it "does not delete the order" do
        delete :destroy, params: { id: orders_package.id }
        expect(Order.find_by_id(order.id)).to eq(order)
      end
    end
  end

  describe 'Executing actions' do
    #
    # Testing that each action does what it is intended to do
    #
    let(:json_record) { subject['orders_package'] }
    let(:error_text) { subject['errors'][0]['message'] }
    let(:new_state) { json_record['state'] }
    let(:current_state) { orders_package.state }

    context 'as a staff member' do
      before { generate_and_set_token(user) }

      describe 'with bad data' do
        let(:orders_package) {create :orders_package}

        it 'fails to execute an action that doesnt exist' do
          put :exec_action, params: { id: orders_package.id, action_name: 'world_peace' }
          expect(error_text).to eq('Action world_peace is not possible at the moment')
        end
      end

      describe 'Cancelling' do
        let(:order) { create :order, :with_state_submitted }
        let(:orders_package) {create :orders_package, :with_state_designated, order_id: order.id}

        it 'cancels the designation successfully' do
          expect(current_state).to eq('designated')

          put :exec_action, params: { id: orders_package.id, action_name: 'cancel' }
          expect(status).to eq(200)
          expect(orders_package.reload.state).to eq('cancelled')
          expect(new_state).to eq('cancelled')
        end
      end

      describe 'Redesignating' do
        let(:order) { create :order, :with_state_submitted }
        let(:order2) { create :order, :with_state_submitted }
        let(:pkg) { create :package, :with_inventory_number, received_quantity: 10  }
        let(:orders_package) {create :orders_package, :with_state_cancelled, order_id: order.id, package: pkg}

        before do
          initialize_inventory(pkg)
          touch(orders_package)
        end

        it 'redesignates the designation successfully' do
          expect(current_state).to eq('cancelled')

          put :exec_action, params: { id: orders_package.id, action_name: 'redesignate', order_id: order2.id }
          expect(status).to eq(200)
          expect(orders_package.reload.order_id).to eq(order2.id)
          expect(new_state).to eq('designated')
          expect(orders_package.reload.state).to eq('designated')
        end
      end

      describe 'Editing Quantity' do
        context 'of a designated orders_package' do
          let(:pkg) { create :package, :with_inventory_record, received_quantity: 10  }
          let(:order) { create :order, :with_state_dispatching }
          let(:orders_package) {
            create(:orders_package, :with_state_designated, order_id: order.id, package_id: pkg.id, quantity: 2)
          }

          before do
            touch(orders_package)
            initialize_inventory(pkg)
          end

          it 'updates correctly' do
            expect(pkg.reload.available_quantity).to eq(8)
            put :exec_action, params: { id: orders_package.id, action_name: 'edit_quantity', quantity: 9 }
            expect(status).to eq(200)
            expect(pkg.reload.available_quantity).to eq(1)
            expect(orders_package.reload.quantity).to eq(9)
          end

          it 'fails if requesting too much' do
            expect(pkg.reload.available_quantity).to eq(8)
            put :exec_action, params: { id: orders_package.id, action_name: 'edit_quantity', quantity: 11 }
            expect(status).to eq(422)
            expect(error_text).to eq('The selected quantity (11) is unavailable')
          end

          it 'fails if we dont pass a desired quantity' do
            put :exec_action, params: { id: orders_package.id, action_name: 'edit_quantity' }
            expect(status).to eq(422)
            expect(error_text).to match(/^Invalid quantity/)
          end
        end
      end

      describe 'Dispatching' do
        context 'items of a processed order' do
          let(:order) { create :order, :with_state_dispatching }
          let(:package) { create(:package, received_quantity: 10) }
          let(:orders_package) { create :orders_package, :with_state_designated, order_id: order.id, package: package, quantity: package.received_quantity }

          before do
            initialize_inventory(package)
          end

          it 'dispatches the packages successfully' do
            expect(current_state).to eq('designated')

            put :exec_action, params: { id: orders_package.id, action_name: 'dispatch', quantity: 10, location_id: package.locations.first }

            expect(status).to eq(200)
            expect(new_state).to eq('dispatched')
            expect(orders_package.reload.state).to eq('dispatched')
            expect(package.reload.locations.length).to eq(0)
          end
        end

        context 'items of an unprocessed order' do
          let(:order) { create :order, :with_state_processing }
          let(:package) { create(:package, :with_inventory_record, received_quantity: 10) }
          let(:orders_package) { create :orders_package, :with_state_designated, order: order, package: package, quantity: package.received_quantity }

          it 'fails to dispatch the packages' do
            expect(current_state).to eq('designated')

            put :exec_action, params: { id: orders_package.id, action_name: 'dispatch', quantity: 10, location_id: package.locations.first.id }

            expect(status).to eq(422)
            expect(error_text).to eq("Cannot dispatch packages from an unprocessed order")
          end
        end
      end

      describe 'Undispatching' do
        let(:location) { create(:location) }
        let(:order) { create :order, :with_state_dispatching }
        let(:quantity) { 10 }
        let(:package) { create(:package, :with_inventory_record, received_quantity: quantity) } # 0 quantity because it has been dispatched
        let(:orders_package) { create :orders_package, :with_inventory_record, :with_state_dispatched, order: order, package: package, quantity: quantity }

        it 'fails to undispatch the packages if no valid location is provided' do
          expect(current_state).to eq('dispatched')
          put :exec_action, params: { id: orders_package.id, action_name: 'undispatch'}
          expect(status).to eq(422)
          expect(error_text).to match(/^Couldn't find Location without an ID/)
          expect(orders_package.reload.state).to eq('dispatched')
        end

        it 'undispatches the packages successfully' do
          expect(current_state).to eq('dispatched')

          put :exec_action, params: { id: orders_package.id, action_name: 'undispatch', location_id: location.id }
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
