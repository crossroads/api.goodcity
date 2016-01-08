require 'rails_helper'

describe Api::V1::LocationSerializer do

  let(:location)   { build(:location) }
  let(:serializer) { Api::V1::LocationSerializer.new(location) }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['location']['id']).to eql(location.id)
    expect(json['location']['area']).to eql(location.area)
    expect(json['location']['building']).to eql(location.building)
  end
end
