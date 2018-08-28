require 'rails_helper'

RSpec.describe Api::V1::RequestsController, type: :controller do

  let(:user)  { create(:user, :with_can_manage_requests_permission, role_name: 'Supervisor') }
  let(:request) { create(:request) }
  let(:request_params) { FactoryBot.attributes_for(:request) }
  let(:parsed_body) { JSON.parse(response.body ) }

  describe "POST request/1" do
    before { generate_and_set_token(user) }

    it "returns 201", :show_in_doc do
      expect {
        post :create, request: request_params
      }.to change(Request, :count).by(1)
      expect(response.status).to eq(201)
    end
  end

  describe "PUT request/1 : update request" do
    before { generate_and_set_token(user) }

    it "Updates request record", :show_in_doc do
      params = request_params
      put :update, id: request.id, delivery: params
      expect(response.status).to eq(200)
      expect(request.reload.quantity).to eq(request.quantity)
    end
  end

  describe "DELETE request/1" do
    before { generate_and_set_token(user) }

    it "returns 200", :show_in_doc do
      delete :destroy, id: request.id
      expect(response.status).to eq(200)
      body = JSON.parse(response.body)
      expect(body).to eq( {} )
    end
  end

end
