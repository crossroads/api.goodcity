require "rails_helper"

RSpec.describe Api::V1::OrdersPackagesController, type: :controller do
  let(:orders_package) { create :orders_package }
  let(:order) { create :order, :with_state_draft }
  let(:user) { create(:user_with_token, :with_can_manage_orders_packages_permission, role_name: 'Reviewer') }
  let(:charity_user) { create(:user_with_token, :with_can_manage_orders_packages_permission, role_name: 'Charity') }
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
      order = create :order
      package = create :package, quantity: 8, received_quantity: 8
      3.times{ create :orders_package, order_id: order.id, package_id: package.id, state: 'designated', quantity: 2 }
      get :index, search_by_package_id: package.id
      expect( subject["orders_packages"].size ).to eq(3)
    end
  end

  describe "DELETE orders_package/1 " do
    before(:all) do
      WebMock.disable!
    end

    after(:all) do
      WebMock.enable!
    end

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

  describe 'Executing an action' do
    let!(:dispatch_location) { create(:location, :dispatched) }
    let(:json_record) { subject['orders_package'] }

    context 'as a staff member' do
      before { generate_and_set_token(user) }

      describe 'when sending bad data' do
        let(:orders_package) {create :orders_package}

        it 'fails to execute an action that doesnt exist' do
          delete :exec_action, id: orders_package.id, action_name: 'world_peace'
          expect(subject['errors'][0]['message']).to eq(
            'Action world_peace is not possible at the moment'
          )
        end
      end

      describe 'CANCEL' do
        let(:order) { create :order, :with_state_submitted }
        let(:orders_package) {create :orders_package, :with_state_designated, order_id: order.id}

        it 'cancels the designation successfully' do
          expect(orders_package.state).to eq('designated')
          delete :exec_action, id: orders_package.id, action_name: 'cancel'
          expect(response.status).to eq(200)
          expect(orders_package.reload.state).to eq('cancelled')
          expect(json_record['state']).to eq('cancelled')
          expect(json_record['allowed_actions']).to eq([
            { "name" => "redesignate", "enabled" => true }
          ])
        end
      end

      describe 'REDESIGNATE' do
        let(:order) { create :order, :with_state_submitted }
        let(:order2) { create :order, :with_state_submitted }
        let(:orders_package) {create :orders_package, :with_state_cancelled, order_id: order.id}

        it 'redesignates the designation successfully' do
          expect(orders_package.state).to eq('cancelled')
          delete :exec_action, id: orders_package.id, action_name: 'redesignate', order_id: order2.id
          expect(response.status).to eq(200)
          expect(orders_package.reload.state).to eq('designated')
          expect(orders_package.reload.order_id).to eq(order2.id)
          expect(json_record['state']).to eq('designated')
          expect(json_record['allowed_actions']).to eq([
            {"name"=>"edit_quantity", "enabled"=>false},
            {"name"=>"cancel", "enabled"=>true},
            {"name"=>"dispatch", "enabled"=>true}
          ])
        end
      end

      describe 'DISPATCH' do
        let(:order) { create :order, :with_state_dispatching }
        let(:orders_package) {create :orders_package, :with_state_designated, order_id: order.id}

        it 'dispatches the packages successfully' do
          expect(orders_package.state).to eq('designated')
          delete :exec_action, id: orders_package.id, action_name: 'dispatch'
          expect(response.status).to eq(200)
          expect(orders_package.reload.state).to eq('dispatched')
          expect(json_record['state']).to eq('dispatched')
          expect(json_record['allowed_actions']).to eq([
            { "name" => "undispatch", "enabled" => true }
          ])
        end
      end

      describe 'UNDISPATCH' do
        let(:order) { create :order, :with_state_dispatching }
        let(:orders_package) {create :orders_package, :with_state_dispatched, order_id: order.id}

        it 'dispatches the packages successfully' do
          expect(orders_package.state).to eq('dispatched')
          delete :exec_action, id: orders_package.id, action_name: 'undispatch'
          expect(response.status).to eq(200)
          expect(orders_package.reload.state).to eq('designated')
          expect(json_record['state']).to eq('designated')
          expect(json_record['allowed_actions']).to eq([
            {"name"=>"edit_quantity", "enabled"=>false},
            {"name"=>"cancel", "enabled"=>true},
            {"name"=>"dispatch", "enabled"=>true}
          ])
        end
      end
    end
  end
end
