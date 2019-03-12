require 'rails_helper'

describe Api::V1::OfferSummarySerializer do

  let(:offer)      { create(:offer, :with_items) }
  let(:serializer) { Api::V1::OfferSummarySerializer.new(offer, root: 'offer').as_json }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "should only have the user and images associations" do
    expect(json.keys).to include("user")
    expect(json.keys).to include("images")
    expect(json.keys).to include("offer")
    expect(json.keys).not_to include("items")
    expect(json.keys).not_to include("messages")
    expect(json.keys).not_to include("gogovan_transport")
    expect(json.keys).not_to include("crossroads_transport")
    expect(json.keys).not_to include("cancellation_reason")
  end

  it "should include a display image" do
    rec = json['offer']
    expect(rec['display_image_id']).not_to be_nil
    expect(rec['display_image_id']).to eq(offer.items.first.images.first.id)

    img = json['images'].detect { |im| im['id'] == rec['display_image_id'] }
    expect(img).not_to eq(nil)
  end
end
