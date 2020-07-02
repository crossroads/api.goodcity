require 'rails_helper'

describe Api::V1::StocktakeSerializer do

  let(:record) { build(:stocktake) }
  let(:serializer) { Api::V1::StocktakeSerializer.new(record).as_json }
  let(:json) { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['stocktake']['id']).to eql(record.id)
    expect(json['stocktake']['location_id']).to eql(record.location_id)
    expect(json['stocktake']['name']).to eql(record.name)
  end

  it "Includes associations" do
    expect(json['packages'].length).to eq(1)
    expect(json['packages'][0]['id']).to eq(record.package.id)
  end
end
