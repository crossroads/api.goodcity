require 'rails_helper'

RSpec.describe Api::V1::GoodcityRequestsController, type: :controller do

  let(:user)  { create(:user, :with_can_manage_goodcity_requests_permission, role_name: 'Supervisor') }
  let(:charity_user) { create :user, :charity }
  let(:goodcity_request) { create(:goodcity_request) }
  let(:goodcity_request_params) { FactoryBot.attributes_for(:goodcity_request) }
  let(:parsed_body) { JSON.parse(response.body ) }
  let(:requests_fetched) do
    parsed_body['goodcity_requests'].map {|r| GoodcityRequest.find(r['id']) }
  end

  describe "GET goodicty_request" do

    before do
      generate_and_set_token(user)
    end

    it "returns 200" do
      get :index
      expect(response.status).to eq(200)
    end

    it "supports filtering requests by order id" do
      (1..3).each { |i| create :order, id: i }
      (1..3).each { |i| create :goodcity_request, order: Order.find(i) }
      get :index, order_ids: '1,2'
      expect(requests_fetched.length).to eq(2)
      requests_fetched.each do |r|
        expect(r.order_id).to be_in([1,2])
      end
    end

    context "As a charity user" do

      let(:order) { create :order, created_by: charity_user }
      let(:anonymous_order) { create :order }

      before do
        generate_and_set_token(charity_user)
      end

      it "returns the goodcity requests created by the current user" do
        create :goodcity_request
        create :goodcity_request, created_by: charity_user
        create :goodcity_request, created_by: charity_user
        get :index
        expect(requests_fetched.length).to eq(2)
        requests_fetched.each do |r|
          expect(r.created_by_id).to eq(charity_user.id)
        end
      end

      it "also returns the goodcity requests of the user's orders" do
        o = create :order, created_by: charity_user
        create :goodcity_request
        create :goodcity_request, order: o
        create :goodcity_request, order: o
        get :index
        expect(requests_fetched.length).to eq(2)
        requests_fetched.each do |r|
          expect(r.order.created_by_id).to eq(charity_user.id)
        end
      end
    end
  end

  describe "POST goodcity_request/1" do
    before { generate_and_set_token(user) }

    it "returns 201", :show_in_doc do
      expect {
        post :create, goodcity_request: goodcity_request_params
      }.to change(GoodcityRequest, :count).by(1)
      expect(response.status).to eq(201)
    end

    context "As a charity user" do
      let(:organisation) { charity_user.active_organisations.first }
      let(:package_type) { create(:package_type) }
      let(:order) { create :order, created_by: charity_user }
      let(:anonymous_order) { create :order }
      let(:organistion_order) { create :order, organisation: organisation }

      before do
        generate_and_set_token(charity_user)
      end

      it "allows me to create a request for my own organisation", :show_in_doc do
        expect {
          post :create, goodcity_request: {
            order_id: organistion_order.id, 
            package_type: package_type.id,
            quantity: 1,
            description: "foo"
          }
        }.to change(GoodcityRequest, :count).by(1)
        expect(response.status).to eq(201)
      end

      it "forbids me to create a request for an order of another organisation", :show_in_doc do
        expect {
          post :create, goodcity_request: {
            order_id: anonymous_order.id, 
            package_type: package_type.id,
            quantity: 1,
            description: "foo"
          }
        }.to change(GoodcityRequest, :count).by(0)
        expect(response.status).to eq(403)
      end
    end
  end

  describe "PUT goodcity_request/1 : update goodcity_request" do
    before { generate_and_set_token(user) }
    let(:gc_request) { create(:goodcity_request, quantity: 5) }

    it "Updates goodcity_request record", :show_in_doc do
      put :update, id: goodcity_request.id, goodcity_request: gc_request.attributes.except(:id)
      expect(response.status).to eq(200)
      expect(goodcity_request.reload.quantity).to eq(goodcity_request.quantity)
    end
  end

  describe "DELETE goodcity_request/1" do
    before { generate_and_set_token(user) }

    it "returns 200", :show_in_doc do
      delete :destroy, id: goodcity_request.id
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body).to eq( {} )
    end
  end
end