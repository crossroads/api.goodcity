require 'rails_helper'

describe Api::V1::TerritorySerializer do

  let(:territory) { build(:territory) }

  it "creates JSON" do
    serializer = Api::V1::TerritorySerializer.new(territory)
    json = JSON.parse( serializer.to_json )
    expect(json['territory']['id']).to eql(territory.id)
    expect(json['territory']['name']).to eql(territory.name)
    expect(json['territory']['name_zh_tw']).to eql(territory.name_zh_tw)
  end

end
