require 'rails_helper'

describe Api::V1::BrowsePackageSerializer do

  let(:package)  { build(:package, :with_inventory_number) }
  let(:serializer) { Api::V1::BrowsePackageSerializer.new(package).as_json }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['browse_package']['length']).to eql(package.length)
    expect(json['browse_package']['height']).to eql(package.height)
    expect(json['browse_package']['width']).to eql(package.width)
    expect(json['browse_package']['quantity']).to eql(package.quantity)
    expect(json['browse_package']['notes']).to eql(package.notes)
    expect(json['browse_package']['rejected_at']).to eql(package.rejected_at)
    expect(json['browse_package']['received_at']).to eql(package.received_at)
    expect(json['browse_package']['inventory_number']).to eql(package.inventory_number)
    expect(json['browse_package']['package_type_id']).to eql(package.package_type_id)
  end
end
