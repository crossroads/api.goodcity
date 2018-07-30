require 'rails_helper'

describe Api::V1::PackagesLocationSerializer do
  let(:packages_location) { build :packages_location }
  let(:serializer) { Api::V1::PackagesLocationSerializer.new(packages_location).as_json }
  let(:json)       { JSON.parse( serializer.to_json ) }


  it 'creates JSON' do
    expect(json['packages_location']['quantity']).to eql(packages_location.quantity)
    expect(json['packages_location']['package_id']).to eql(packages_location.package_id)
    expect(json['packages_location']['item_id']).to eql(packages_location.package_id)
    expect(json['packages_location']['location_id']).to eql(packages_location.location_id)
  end
end
