require 'rails_helper'

describe Api::V1::ItemTypeSerializer do

  let(:item_type) { build(:item_type) }

  it "creates JSON" do
    serializer = Api::V1::ItemTypeSerializer.new(item_type)
    json = JSON.parse( serializer.to_json )
    expect(json['item_type']['id']).to eql(item_type.id)
    expect(json['item_type']['name']).to eql(item_type.name)
    expect(json['item_type']['code']).to eql(item_type.code)
  end

  it "translates JSON" do
    I18n.locale = 'zh-tw'
    serializer = Api::V1::ItemTypeSerializer.new(item_type)
    json = JSON.parse( serializer.to_json )
    expect(json['item_type']['name']).to eql(item_type.name_zh_tw)
  end

end
