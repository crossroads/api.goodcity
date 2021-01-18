require 'rails_helper'

RSpec.describe Api::V1::TransportsController, type: :controller do

  let(:user) { create(:user, :with_token) }
  let(:district) { create :district }
  let(:offer) { create :offer }
  let(:scheduled_at)   { "Wed, 30 Dec 2020 15:10:08.000000000 +0800" }
  let!(:provider) { create(:transport_provider) }

  describe "GET providers" do
    before { generate_and_set_token(user) }

    it "returns 200", :show_in_doc do
      get :providers
      expect(response.status).to eq(200)
    end

    it "return providers" do
      get :providers
      body = JSON.parse(response.body)
      expect( body["transport_providers"].length ).to eq(TransportProvider.count)
    end
  end

  describe "POST quote" do
    before { generate_and_set_token(user) }

    let(:quote_response) {
      {
        "vehicle_type" => "van",
        "estimated_price" => {"amount" => 15000, "currency" => "HKD"},
        "estimated_price_breakdown" => [{"key" => "fee", "amount" => 15000}],
      }
    }

    let(:quotation_attributes) {
      {
        "provider": "GOGOX",
        'vehicle_type': 'van',
        "scheduled_at": scheduled_at,
        "district_id": district.id.to_s,
        "offer_id": offer.id.to_s
      }
    }

    it "should trigger TransportService Service" do
      mock_object = instance_double(TransportService, quotation: quote_response)
      allow(TransportService).to receive(:new).with(quotation_attributes)
                        .and_return(mock_object)

      post :quote, params: quotation_attributes

      expect( JSON.parse(response.body) ).to eq(quote_response)
    end
  end

  describe "POST book" do
    before { generate_and_set_token(user) }

    let(:order_response) {
      {
        "vehicle_type" => "van",
        "price" => {"amount" => 15000, "currency" => "HKD"},
        "price_breakdown" => [{"key" => "fee", "amount" => 15000}],
      }
    }

    let(:order_attributes) {
      {
        "provider": "GOGOX",
        'vehicle_type': "van",
        "scheduled_at": scheduled_at,
        "district_id": district.id.to_s,
        "offer_id": offer.id.to_s,
        "pickup_contact_name": "Sarah",
        "pickup_contact_phone": "+85251111117",
        "pickup_street_address": "Street"
      }
    }

    it "should trigger TransportService Service" do
      mock_object = instance_double(TransportService, book: order_response)
      allow(TransportService).to receive(:new).with(order_attributes)
                                  .and_return(mock_object)

      post :book, params: order_attributes

      expect(JSON.parse(response.body)).to eq(order_response)
    end
  end

  describe "GET show" do
    before { generate_and_set_token(user) }

    let(:booking_id) { "2f859363-5c43-4fe2-9b91-6c6c43d610d2" }
    let!(:transport_order) {
      create(:transport_order, order_uuid: booking_id, transport_provider: provider)
    }

    let(:status_response) {
      transport_order.attributes.to_json
    }

    let(:status_attributes) {
      {
        booking_id: booking_id,
        provider: "GOGOX"
      }
    }

    it "should trigger TransportService Service" do
      mock_object = instance_double(TransportService, status: status_response)
      allow(TransportService).to receive(:new).with(status_attributes)
                        .and_return(mock_object)

      get :show, params: {order_uuid: booking_id}

      expect( JSON.parse(response.body) ).to eq(JSON.parse(status_response))
    end
  end

  describe "POST cancel" do
    before { generate_and_set_token(user) }

    let(:booking_id) { "2f859363-5c43-4fe2-9b91-6c6c43d610d2" }
    let!(:transport_order) {
      create(:transport_order, order_uuid: booking_id, transport_provider: provider)
    }

    let(:cancel_response) {
      transport_order.attributes.to_json
    }

    let(:cancel_attributes) {
      {
        booking_id: booking_id,
        provider: "GOGOX"
      }
    }

    it "should trigger TransportService Service" do
      mock_object = instance_double(TransportService, cancel: cancel_response)
      allow(TransportService).to receive(:new).with(cancel_attributes)
                        .and_return(mock_object)

      post :cancel, params: {order_uuid: booking_id}

      expect( JSON.parse(response.body) ).to eq(JSON.parse(cancel_response))
    end
  end

end
