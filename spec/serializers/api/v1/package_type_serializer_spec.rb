require 'rails_helper'

describe Api::V1::PackageTypeSerializer do

  let(:package_type)  { build(:package_type) }
  let(:serializer) { Api::V1::PackageTypeSerializer.new(package_type) }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['package_type']['id']).to eql(package_type.id)
    expect(json['package_type']['name']).to eql(package_type.name)
    expect(json['package_type']['code']).to eql(package_type.code)
  end

  it "translates JSON" do
    I18n.locale = 'zh-tw'
    expect(json['package_type']['name']).to eql(package_type.name_zh_tw)
  end

  it "returns name_zh_tw for chinese" do
    I18n.locale = 'zh-tw'
    expect(described_class.new("test").name__sql).to eq("coalesce(NULLIF(name_zh_tw, ''), name_en)")
  end

  it "returns name_en for english" do
    I18n.locale = 'en'
    expect(described_class.new("test").name__sql).to eq("coalesce(NULLIF(name_en, ''), name_en)")
  end

end
