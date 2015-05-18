require 'rails_helper'

describe Api::V1::PackageTypeSerializer do

  let(:package_type)  { build(:package_type) }
  let(:serializer) { Api::V1::PackageTypeSerializer.new(package_type) }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it_behaves_like 'name_with_language'

  it "creates JSON" do
    expect(json['package_type']['id']).to eql(package_type.id)
    expect(json['package_type']['name']).to eql(package_type.name)
    expect(json['package_type']['code']).to eql(package_type.code)
  end

  it "translates JSON" do
    I18n.locale = 'zh-tw'
    expect(json['package_type']['name']).to eql(package_type.name_zh_tw)
  end

end
