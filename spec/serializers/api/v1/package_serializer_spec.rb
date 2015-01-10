require 'rails_helper'

describe Api::V1::PackageSerializer do

  let(:package)  { build(:package, :with_item) }
  let(:serializer) { Api::V1::PackageSerializer.new(package) }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['package']['length']).to eql(package.length)
    expect(json['package']['height']).to eql(package.height)
    expect(json['package']['width']).to eql(package.width)
    expect(json['package']['quantity']).to eql(package.quantity)
    expect(json['package']['notes']).to eql(package.notes)
    expect(json['package']['rejected_at']).to eql(package.rejected_at)
    expect(json['package']['received_at']).to eql(package.received_at)
    expect(json['package']['item_id']).to eql(package.item_id)
    expect(json['package']['package_type_id']).to eql(package.package_type_id)
  end
end
