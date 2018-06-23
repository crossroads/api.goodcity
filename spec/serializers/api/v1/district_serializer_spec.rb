require 'rails_helper'

describe Api::V1::DistrictSerializer do

  let(:district)   { build(:district) }
  let(:serializer) { Api::V1::DistrictSerializer.new(district).as_json }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it_behaves_like 'name_with_language'

  it "creates JSON" do
    expect(json['district']['id']).to eql(district.id)
    expect(json['district']['name']).to eql(district.name)
    #~ expect(json['territories'].first['id']).to eql(district.territory.id)
    #~ expect(json['territories'].first['name']).to eql(district.territory.name)
  end

  it "translates JSON" do
    I18n.locale = 'zh-tw'
    expect(json['district']['name']).to eql(district.name_zh_tw)
    #~ expect(json['territories'].first['name']).to eql(district.territory.name_zh_tw)
  end

end
