require 'rails_helper'

describe Api::V1::ItemTypeSerializer do

  let(:item_type)  { build(:item_type) }
  let(:serializer) { Api::V1::ItemTypeSerializer.new(item_type) }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it_behaves_like 'name_with_language'

  it "creates JSON" do
    expect(json['item_type']['id']).to eql(item_type.id)
    expect(json['item_type']['name']).to eql(item_type.name)
    expect(json['item_type']['code']).to eql(item_type.code)
    expect(json['item_type']['parent_id']).to eql(item_type.parent_id)
    expect(json['item_type']['is_item_type_node']).to eql(item_type.is_item_type_node)
  end

  it "translates JSON" do
    I18n.locale = 'zh-tw'
    expect(json['item_type']['name']).to eql(item_type.name_zh_tw)
  end

end
