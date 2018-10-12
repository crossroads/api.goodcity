require 'rails_helper'

RSpec.describe Api::V1::GoodcityRequestsController, type: :controller do

  let(:user)  { create(:user, :with_can_manage_goodcity_requests_permission, role_name: 'Supervisor') }
  let(:goodcity_request) { create(:goodcity_request) }
  let(:goodcity_request_params) { FactoryBot.attributes_for(:goodcity_request) }
  let(:parsed_body) { JSON.parse(response.body ) }

  describe "POST goodcity_request/1" do
    before { generate_and_set_token(user) }

    it "returns 201", :show_in_doc do
      expect {
        post :create, goodcity_request: goodcity_request_params
      }.to change(GoodcityRequest, :count).by(1)
      expect(response.status).to eq(201)
    end
  end

  describe "PUT goodcity_request/1 : update goodcity_request" do
    before { generate_and_set_token(user) }
    let(:gc_request) { create(:goodcity_request, quantity: 5) }

    it "Updates goodcity_request record", :show_in_doc do
      put :update, id: goodcity_request.id, goodcity_request: gc_request.attributes.except(:id)
      expect(response.status).to eq(201)
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
