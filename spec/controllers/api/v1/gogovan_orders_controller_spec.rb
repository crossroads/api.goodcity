require 'rails_helper'

RSpec.describe Api::V1::GogovanOrdersController, type: :controller do

  let(:user) { create(:user_with_token) }
  let(:gogovan_order) { create(:gogovan_order) }
  let(:serialized_order) { Api::V1::GogovanOrderSerializer.new(gogovan_order) }
  let(:order_attributes) {
    {
      "pickupTime" => "Wed Nov 26 2014 21:30:00 GMT+0530 (IST)",
      "districtId" => "55",
      "needEnglish" => "true",
      "needCart" => "true",
      "needCarry" => "true"
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
        "district_id" => "55",
        "need_english" => true,
        "need_cart" => true,
        "need_carry" => true }
    }
  }

  let(:order_details_hash) {
    Hash[order_details['gogovan_order'].map{|(k,v)| [k.camelize(:lower),v]}]
  }

  describe "POST gogovan_orders/calculate_price" do
    context "donor" do
      before { generate_and_set_token(user) }
      it "can initiate gogovan order and get price", :show_in_doc do
        allow(GogovanOrder).to receive(:place_order).with(user, order_attributes).and_return(price_details)
        post :calculate_price, order_attributes, format: 'json'
        expect(response.status).to eq(200)
        expect(response.body).to eq(price_details.to_json)
      end
    end
  end

  describe "POST gogovan_orders/confirm_order" do
    context "donor" do
      before { generate_and_set_token(user) }
      it "can initiate gogovan order and get price", :show_in_doc do
        allow(GogovanOrder).to receive(:book_order).with(user, order_details_hash).and_return(gogovan_order)
        post :confirm_order, order_details, format: 'json'
        expect(response.status).to eq(200)
        expect( response.body ).to eq(serialized_order.to_json)
      end
    end
  end

end
