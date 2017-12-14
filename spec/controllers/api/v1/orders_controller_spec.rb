require "rails_helper"

RSpec.describe Api::V1::OrdersController, type: :controller do
    let(:user)  { create :user_with_token }
    let(:order)  { create :order }
    let(:offer) { create :offer, created_by: user }
    let(:item)  { create(:item, offer: offer) }
    let(:package) { create :package }
    let(:order_params) { order.attributes.except("id") }

  subject { JSON.parse(response.body) }

  describe "POST create order" do
    before { generate_and_set_token(user) }
    it "should response 201 status on create" do
      post :create, order: order_params , package: package
      expect(response.status).to eq(201)
    end
  end
end
