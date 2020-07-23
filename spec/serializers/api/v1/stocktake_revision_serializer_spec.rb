require 'rails_helper'

describe Api::V1::StocktakeRevisionSerializer do

  let(:record) { build(:stocktake_revision) }
  let(:serializer) { Api::V1::StocktakeRevisionSerializer.new(record).as_json }
  let(:json) { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['stocktake_revision']['id']).to eql(record.id)
    expect(json['stocktake_revision']['package_id']).to eql(record.package_id)
    expect(json['stocktake_revision']['stocktake_id']).to eql(record.stocktake_id)
    expect(json['stocktake_revision']['quantity']).to eql(record.quantity)
  end

  it "Includes associations" do
    expect(json['packages'].length).to eq(1)
    expect(json['packages'][0]['id']).to eq(record.package.id)
  end
end
