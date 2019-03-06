require 'rails_helper'

describe Api::V1::OfferSummarySerializer do

  let(:ggv_order)  { create(:gogovan_order, :with_delivery) }
  let(:offer)      { ggv_order.delivery.offer }
  let(:serializer) { Api::V1::OfferSummarySerializer.new(offer).as_json }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "should only have the users association" do
    expect(json.keys).to include("user")
    expect(json.keys).not_to include("items")
    expect(json.keys).not_to include("messages")
    expect(json.keys).not_to include("gogovan_transport")
    expect(json.keys).not_to include("crossroads_transport")
    expect(json.keys).not_to include("cancellation_reason")
  end
end
