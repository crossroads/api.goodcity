require 'rails_helper'

describe Api::V1::TerritorySerializer do

  let(:territory)  { create(:territory) }
  let(:serializer) { Api::V1::TerritorySerializer.new(territory) }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it_behaves_like 'name_with_language'

  it "creates JSON" do
    expect(json['territory']['id']).to eql(territory.id)
    expect(json['territory']['name']).to eql(territory.name)
  end

  it "translates JSON" do
    I18n.locale = 'zh-tw'
    expect(json['territory']['name']).to eql(territory.name_zh_tw)
  end

end
