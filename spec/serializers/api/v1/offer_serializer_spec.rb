require 'rails_helper'

describe Api::V1::OfferSerializer do

  let(:offer) { build(:offer) }

  it "creates JSON" do
    serializer = Api::V1::OfferSerializer.new(offer)
    json = JSON.parse( serializer.to_json )
    expect(json['offer']['id']).to eql(offer.id)
    expect(json['offer']['language']).to eql(offer.language)
    expect(json['offer']['state']).to eql(offer.state)
  end

end
