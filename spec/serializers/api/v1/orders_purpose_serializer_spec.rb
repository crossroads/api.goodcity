require 'rails_helper'

describe Api::V1::OrdersPurposeSerializer do

  let(:orders_purpose)   { build(:orders_purpose) }
  let(:serializer) { Api::V1::OrdersPurposeSerializer.new(orders_purpose) }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json["orders_purpose"]["purpose_id"]).to eq(orders_purpose.purpose.id)
    expect(json['purposes'][0]['name_en']).to eql(orders_purpose.purpose.name_en)
    expect(json['purposes'][0]['name_zh_tw']).to eql(orders_purpose.purpose.name_zh_tw)
  end
end
