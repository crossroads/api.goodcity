require 'rails_helper'

describe Api::V1::RequestSerializer do

  let(:request) { build(:request) }
  let(:serializer) { Api::V1::RequestSerializer.new(request).as_json }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['request']['id']).to eql(request.id)
    expect(json['request']['quantity']).to eql(request.quantity)
    expect(json['request']['description']).to eql(request.description)
    expect(json['request']['code_id']).to eql(request.package_type_id)
  end
end
