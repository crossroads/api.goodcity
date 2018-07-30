require 'rails_helper'

describe Api::V1::PurposeSerializer do

  let(:purpose)   { build(:purpose) }
  let(:serializer) { Api::V1::PurposeSerializer.new(purpose).as_json }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['purpose']['name_en']).to eql(purpose.name_en)
    expect(json['purpose']['name_zh_tw']).to eql(purpose.name_zh_tw)
  end
end
