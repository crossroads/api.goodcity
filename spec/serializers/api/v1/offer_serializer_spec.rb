require 'rails_helper'

describe Api::V1::OfferSerializer do

  let(:offer)      { build(:offer, :submitted) }
  let(:serializer) { Api::V1::OfferSerializer.new(offer) }
  let(:json)       { JSON.parse( serializer.to_json ) }

  let(:ggv_order)   { create(:gogovan_order, :with_delivery) }
  let(:offer1)      { ggv_order.delivery.offer }
  let(:serializer1) { Api::V1::OfferSerializer.new(offer1)  }
  let(:json1)       { JSON.parse( serializer1.to_json ) }

  it "creates JSON" do
    expect(json['offer']['id']).to eql(offer.id)
    expect(json['offer']['language']).to eql(offer.language)
    expect(json['offer']['state']).to eql(offer.state)
    expect(json['offer']['submitted_at'].to_date).
      to eql(offer.submitted_at.to_date)
  end

  context "Driver" do
    before { User.current_user = nil }
    it "creates JSON" do
      expect(json1['offer']['id']).to eql(offer1.id)
      expect(json1['offer']['language']).to eql(offer1.language)
      expect(json1['offer']['state']).to eql(offer1.state)
      expect(json1['messages']).to eql(nil)
      expect(json1['gogovan_transport']).to eql(nil)
    end
  end
end
