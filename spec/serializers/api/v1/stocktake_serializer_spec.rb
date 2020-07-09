require 'rails_helper'

describe Api::V1::StocktakeSerializer do

  let(:package) { create(:package, :with_inventory_record, received_quantity: 10) }
  let(:record) { build(:stocktake) }
  let(:serializer) { Api::V1::StocktakeSerializer.new(record).as_json }
  let(:json) { JSON.parse( serializer.to_json ) }
  let(:revision) { create(:stocktake_revision, stocktake: record, package: package, quantity: 12) }

  before { touch(revision) }

  it "creates JSON" do
    expect(json['stocktake']['id']).to eql(record.id)
    expect(json['stocktake']['location_id']).to eql(record.location_id)
    expect(json['stocktake']['name']).to eql(record.name)
    expect(json['stocktake']['comment']).to eql(record.comment)
  end

  it "Includes associations" do
    expect(json['stocktake_revisions'].length).to eq(1)
    expect(json['stocktake_revisions'][0]['id']).to eq(revision.id)
    expect(json['packages'].length).to eq(1)
    expect(json['packages'][0]['id']).to eq(revision.package.id)
  end
end
