require 'rails_helper'

describe Api::V1::TerritorySerializer do

  let(:territory)  { create(:district).territory }
  let(:serializer) { Api::V1::TerritorySerializer.new(territory).as_json }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['territory']['id']).to eql(territory.id)
    expect(json['territory']['name']).to eql(territory.name)
  end

  it "translates JSON" do
    in_locale 'zh-tw' do
      expect(json['territory']['name']).to eql(territory.name_zh_tw)
    end
  end

end
