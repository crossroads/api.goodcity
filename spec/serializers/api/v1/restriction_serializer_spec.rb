require 'rails_helper'

describe Api::V1::RestrictionSerializer do

  let(:restriction) { build(:restriction) }
  let(:serializer)      { Api::V1::RestrictionSerializer.new(restriction).as_json }
  let(:json)            { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['restriction']['id']).to eql(restriction.id)
    expect(json['restriction']['name']).to eql(restriction.name_en)
  end

  it "translates JSON" do
    in_locale 'zh-tw' do
      expect(json['restriction']['name']).to eql(restriction.name_zh_tw)
    end
  end

end
