require 'rails_helper'

describe Api::V1::TerritorySerializer do

  let(:territory)  { create(:territory_districts) }
  let(:serializer) { Api::V1::TerritorySerializer.new(territory) }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['territory']['id']).to eql(territory.id)
    expect(json['territory']['name']).to eql(territory.name)
    expect(json['districts'].first['id']).to eql(territory.districts.find(json['districts'].first['id']).id)
    expect(json['districts'].first['name']).to eql(territory.districts.where('name_zh_tw = ?',
      json['districts'].first['name']).first.name)
  end

  it "translates JSON" do
    I18n.locale = 'zh-tw'
    expect(json['territory']['name']).to eql(territory.name_zh_tw)
  end

end
