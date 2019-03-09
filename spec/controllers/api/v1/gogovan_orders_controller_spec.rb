require 'rails_helper'

RSpec.describe Api::V1::GogovanOrdersController, type: :controller do

  let(:user) { create(:user_with_token) }
  let(:gogovan_order) { create(:gogovan_order) }
  let(:serialized_order) { Api::V1::GogovanOrderSerializer.new(gogovan_order).as_json }
  let(:serialized_order_json) { JSON.parse(serialized_order.to_json) }
  let(:parsed_body) { JSON.parse(response.body) }
  let(:offer) { create(:offer, state: 'scheduled', delivery: delivery) }
  let(:delivery) { create(:gogovan_delivery, gogovan_order: ggv_order)}
  let(:ggv_order) { create(:gogovan_order) }
  let(:order_attributes) {
    {
      "pickupTime" => "Wed Nov 26 2014 21:30:00 GMT+0530 (IST)",
      "districtId" => "11",
      "needEnglish" => "true",
      "needCart" => "true",
      "needCarry" => "true",
      "offerId" => "#{offer.id}"
    }
  }

  let(:price_details) {
    {
      "breakdown" => {
        "fee" => {
          "title" => "Fee",
          "value" => 120 },
        "night_extra_charge" => {
          "title" => "Night Charge",
          "value" => 100 }
      },
      "base" => 120
    }
  }

  let(:order_details) {
    {
      "gogovan_order" => {
        "name" => "John K",
        "mobile" => "+85260001111",
        "pickup_time" => "2014-11-26T16:30:00.000Z",
        "district_id" => 55,
        "need_english" => true,
        "need_cart" => true,
        "need_carry" => true,
        "offer_id" => offer.id }
    }
  }

  describe "POST gogovan_orders/calculate_price" do
    context "donor" do
      before { generate_and_set_token(user) }
      it "can initiate gogovan order and get price", :show_in_doc do
        allow(GogovanOrder).to receive(:place_order).with(user, order_attributes).and_return(price_details)
        post :calculate_price, order_attributes
        expect(response.status).to eq(200)
        expect(response.body).to eq(price_details.to_json)
      end
    end
  end

  describe "GET gogovan_orders/driver_details" do
    before { generate_and_set_token(user) }
    let(:ggv_uuid) { offer.delivery.gogovan_order.ggv_uuid }
    it "returns 200" do
      get :driver_details, id: ggv_uuid
      expect(response.status).to eq(200)
      expect(parsed_body.keys).to include("gogovan_orders")
    end
  end
end
