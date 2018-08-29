require 'rails_helper'

describe Api::V1::GoodcityRequestSerializer do

  let(:goodcity_request) { build(:goodcity_request) }
  let(:serializer) { Api::V1::GoodcityRequestSerializer.new(goodcity_request).as_json }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['goodcity_request']['id']).to eql(goodcity_request.id)
    expect(json['goodcity_request']['quantity']).to eql(goodcity_request.quantity)
    expect(json['goodcity_request']['description']).to eql(goodcity_request.description)
    expect(json['goodcity_request']['code_id']).to eql(goodcity_request.package_type_id)
  end
end
