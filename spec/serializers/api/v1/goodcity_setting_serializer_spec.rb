require 'rails_helper'

describe Api::V1::GoodcitySettingSerializer do

  let(:goodcity_setting) { build(:goodcity_setting) }
  let(:serializer) { Api::V1::GoodcitySettingSerializer.new(goodcity_setting).as_json }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['goodcity_setting']['id']).to eql(goodcity_setting.id)
    expect(json['goodcity_setting']['key']).to eql(goodcity_setting.key)
    expect(json['goodcity_setting']['value']).to eql(goodcity_setting.value)
    expect(json['goodcity_setting']['desc']).to eql(goodcity_setting.desc)
  end
end
