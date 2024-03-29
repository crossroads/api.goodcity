require "rails_helper"

RSpec.describe Api::V1::OrderTransportsController, type: :controller do
  let(:charity_user) { create :user, :charity }
  let(:order) { create :order, created_by_id: charity_user.id }
  let(:other_order) { create :order }
  let(:parsed_body) { JSON.parse(response.body) }

  before { generate_and_set_token(charity_user) }

  describe "Creating order_transports" do
    let(:transport_params) {
      {
        :scheduled_at=>Time.now,
        :timeslot=>"2PM-3PM",
        :transport_type=>"self",
        :order_id=>order.id
      }
    }

    it "returns 201", :show_in_doc do
      post :create, params: { order_transport: transport_params }, as: :json
      expect(response.status).to eq(201)
    end

    it "returns 403 if I don't own the order", :show_in_doc do
      post :create, params: { order_transport: { **transport_params, :order_id=>other_order.id } }, as: :json
      expect(response.status).to eq(403)
    end
  end
end
