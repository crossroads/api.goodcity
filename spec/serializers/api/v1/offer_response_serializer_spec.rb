require 'rails_helper'

describe Api::V1::OfferResponseSerializer do

  let(:offer_response)  { create(:offer_response) }
  let(:serializer) { Api::V1::OfferResponseSerializer.new(offer_response).as_json }
  let(:json) { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    record = json['offer_response']
    expect(record['id']).to eq(offer_response.id)
    expect(record['user_id']).to eq(offer_response.user_id)
    expect(record['offer_id']).to eq(offer_response.offer_id)
  end
end
