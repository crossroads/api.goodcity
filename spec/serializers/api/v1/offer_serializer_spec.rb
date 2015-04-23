require 'rails_helper'

describe Api::V1::OfferSerializer do

  let(:ggv_order)  { create(:gogovan_order, :with_delivery) }
  let(:offer)      { ggv_order.delivery.offer }
  let(:serializer) { Api::V1::OfferSerializer.new(offer) }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['offer']['id']).to eql(offer.id)
    expect(json['offer']['language']).to eql(offer.language)
    expect(json['offer']['state']).to eql(offer.state)
  end

  context "Driver" do
    before { User.current_user = nil }
    it "creates JSON" do
      expect(json['offer']['id']).to eql(offer.id)
      expect(json['offer']['language']).to eql(offer.language)
      expect(json['offer']['state']).to eql(offer.state)
      expect(json['messages']).to eql(nil)
      expect(json['gogovan_transport']).to eql(nil)
    end
  end
end
