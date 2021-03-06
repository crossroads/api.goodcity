require 'rails_helper'

describe Api::V1::PackageTypeSerializer do
  let(:package_type)  { build(:package_type) }
  let(:serializer) { Api::V1::PackageTypeSerializer.new(package_type).as_json }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['package_type']['id']).to eql(package_type.id)
    expect(json['package_type']['name']).to eql(package_type.name)
    expect(json['package_type']['code']).to eql(package_type.code)
    expect(json['package_type']['allow_expiry_date']).to eql(package_type.allow_expiry_date)
  end

  it "translates JSON" do
    in_locale 'zh-tw' do
      expect(json['package_type']['name']).to eql(package_type.name_zh_tw)
    end
  end
end
