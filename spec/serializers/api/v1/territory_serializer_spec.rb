require 'rails_helper'

describe Api::V1::TerritorySerializer do

  let(:territory) { build(:territory) }

  it "creates JSON" do
    serializer = Api::V1::TerritorySerializer.new(territory)
    json = JSON.parse( serializer.to_json )
    expect(json['territory']['id']).to eql(territory.id)
    expect(json['territory']['name']).to eql(territory.name)
  end

end
