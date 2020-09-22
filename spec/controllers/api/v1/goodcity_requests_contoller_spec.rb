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
      (1..3).each { |i| create :order, created_by: user, id: i }
      (1..3).each { |i| create :goodcity_request, order: Order.find(i) }
      get :index, params: { order_ids: '1,2' }
      expect(requests_fetched.length).to eq(2)
      requests_fetched.each do |r|
        expect(r.order_id).to be_in([1,2])
      end
    end

    context "As a charity user" do

      let(:order) { create :order, created_by: charity_user }
      let(:other_order) { create :order }

      before do
        generate_and_set_token(charity_user)
      end

      it "returns the goodcity requests of the user's organisation" do
        order = create :order, created_by: charity_user, organisation_id: charity_user.organisations.first.id
        create :goodcity_request
        create :goodcity_request, order: order, created_by: charity_user
        create :goodcity_request, order: order, created_by: charity_user

        get :index
        expect(requests_fetched.length).to eq(2)
        requests_fetched.each do |r|
          expect(r.created_by_id).to eq(charity_user.id)
        end
      end
    end
  end

  describe "POST goodcity_request/1" do
    before { generate_and_set_token(user) }

    it "returns 201", :show_in_doc do
      expect {
        post :create, params: { goodcity_request: goodcity_request_params }
      }.to change(GoodcityRequest, :count).by(1)
      expect(response.status).to eq(201)
    end

    context "As a charity user" do
      let(:package_type) { create(:package_type) }
      let(:order) { create :order, created_by: charity_user }
      let(:other_order) { create :order }

      before do
        generate_and_set_token(charity_user)
      end

      it "allows me to create a request for my own order", :show_in_doc do
        expect {
          post :create, params: {
            goodcity_request: {
            order_id: order.id,
            package_type: package_type.id,
            quantity: 1,
            description: "foo"
            }
          }
        }.to change(GoodcityRequest, :count).by(1)
        expect(response.status).to eq(201)
      end

      it "it forbids me from creating a request for another user's order", :show_in_doc do
        expect {
          post :create, params: {
            goodcity_request: {
            order_id: other_order.id,
            package_type: package_type.id,
            quantity: 1,
            description: "foo"
            }
          }
        }.not_to change(GoodcityRequest, :count)
        expect(response.status).to eq(403)
      end
    end
  end

  describe "PUT goodcity_request/1 : update goodcity_request" do
    let(:other_user) { create :user }
    let(:order) { create :order, created_by: charity_user }
    let(:other_order) { create :order }
    let(:gc_request) { create(:goodcity_request, order: order, quantity: 5) }
    let(:my_gc_request) { create(:goodcity_request, created_by: charity_user, quantity: 5) }
    let(:other_gc_request) { create(:goodcity_request, created_by: other_user, order: other_order, quantity: 5) }

    before { generate_and_set_token(charity_user) }

    it "Updates goodcity_request record", :show_in_doc do
      put :update, params: { id: gc_request.id, goodcity_request: gc_request.attributes.except(:id) }
      expect(response.status).to eq(200)
      expect(goodcity_request.reload.quantity).to eq(goodcity_request.quantity)
    end

    it "it forbids me from updating a request for another user's order", :show_in_doc do
      put :update, params: { id: other_gc_request.id, goodcity_request: other_gc_request.attributes.except(:id) }
      expect(response.status).to eq(403)
    end
  end

  describe "DELETE goodcity_request/1" do
    before { generate_and_set_token(user) }

    it "returns 200", :show_in_doc do
      delete :destroy, params: { id: goodcity_request.id }
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body).to be_empty
    end
  end
end
