require 'rails_helper'

RSpec.describe Api::V1::OrdersController, type: :controller do
  let(:charity_user) { create :user, :charity, :with_can_manage_orders_permission}
  let!(:order) { create :order, created_by: charity_user }

  let(:user) { create(:user_with_token, :with_multiple_roles_and_permissions,
    roles_and_permissions: { 'Supervisor' => ['can_manage_orders']} )}

  let!(:order_created_by_supervisor) { create :order, created_by: user }

  describe "GET orders" do
    context 'If logged in user is Supervisor in Browse app ' do

      before { generate_and_set_token(user) }

      it "returns 200", :show_in_doc do
        get :index
        expect(response.status).to eq(200)
      end

      it 'returns orders created by logged in user when user is supervisor and if its browse app' do
        set_browse_app_header
        get :index
        body = JSON.parse(response.body)
        expect(body['orders'].count).to eq(1)
        expect(body["orders"][0]['id']).to eq(order_created_by_supervisor.id)
      end
    end

    context 'If logged in user is Charity user' do

      before { generate_and_set_token(charity_user) }

      it "returns 200", :show_in_doc do
        get :index
        expect(response.status).to eq(200)
      end

      it 'returns orders created by logged in user' do
        request.headers["X-GOODCITY-APP-NAME"] = "browse.goodcity"
        get :index
        body = JSON.parse(response.body)
        expect(body['orders'].count).to eq(1)
        expect(body["orders"][0]['id']).to eq(order.id)
      end
    end

    context 'Admin app' do
      before { generate_and_set_token(user) }

      it 'returns all orders as designations for admin app if search text is not present' do
        request.headers["X-GOODCITY-APP-NAME"] = "admin.goodcity"
        get :index
        body = JSON.parse(response.body)
        expect(response.status).to eq(200)
        expect(body['designations'].count).to eq(2)
      end
    end

    context 'Stock App' do
      before { generate_and_set_token(user) }

      it 'returns searched order as designation if search text is present' do
        request.headers["X-GOODCITY-APP-NAME"] = "stock.goodcity"
        get :index, searchText: order.code
        body = JSON.parse(response.body)
        expect(response.status).to eq(200)
        expect(body['designations'].count).to eq(1)
        expect(body["designations"][0]['id']).to eq(order.id)
      end
    end
  end

  describe "PUT orders/1" do
    before { generate_and_set_token(charity_user) }
    let(:draft_order) { create :order, :with_orders_packages, :with_state_draft }

    context 'should merge offline cart orders_packages on login with order' do
      it "if order is in draft state" do
        package = create :package, quantity: 1, received_quantity: 1
        package_ids = draft_order.orders_packages.pluck(:package_id)
        put :update, id: draft_order.id, order: { cart_package_ids: package_ids.push(package.id) }
        expect(response.status).to eq(200)
        expect(draft_order.orders_packages.count).to eq(4)
      end
    end
  end
end
