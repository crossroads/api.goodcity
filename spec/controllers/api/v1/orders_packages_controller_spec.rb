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
end
