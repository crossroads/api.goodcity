require 'rails_helper'

describe Api::V1::OffersPackageSerializer do

  let(:offers_package)  { create(:offers_package) }
  let(:serializer) { Api::V1::OffersPackageSerializer.new(offers_package).as_json }
  let(:json) { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    record = json['offers_package']
    expect(record['id']).to eq(offers_package.id)
    expect(record['item_id']).to eq(offers_package.package_id)
    expect(record['offer_id']).to eq(offers_package.offer_id)
  end
end
