require "rails_helper"

RSpec.describe Api::V1::OrdersPackagesController, type: :controller do
  let(:orders_package) { create :orders_package }
  let(:user) { create(:user_with_token, :reviewer) }


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
      body = JSON.parse(response.body)
      expect( body["orders_packages"].size ).to eq(3)
    end

    it 'returns designated and dispatched orders_packages' do
      order = create :order
      package = create :package
      3.times{ create :orders_package, order_id: order.id, package_id: package.id, state: 'designated' }
      get :index, search_by_package_id: package.id
      body = JSON.parse(response.body)
      expect( body["orders_packages"].size ).to eq(3)
    end
  end
end
