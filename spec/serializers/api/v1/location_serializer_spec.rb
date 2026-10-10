require 'rails_helper'

describe Api::V1::LocationSerializer do

  let(:location)   { build(:location) }
  let(:serializer) { Api::V1::LocationSerializer.new(location).as_json }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['location']['id']).to eql(location.id)
    expect(json['location']['area']).to eql(location.area)
    expect(json['location']['building']).to eql(location.building)
  end

  # A retired location keeps the shared shape: retired_at is never in it, so the legacy apps see no change.
  context "a retired location" do
    let(:location) { create(:location, building: "SER-RET", area: "1", retired_at: 1.day.ago) }

    it "serializes exactly id, building and area" do
      expect(json['location'].keys).to match_array(%w[id building area])
    end

    it "still resolves where a record points at it (a packages_location sideloads it)" do
      pl = create(:packages_location, location: location, package: create(:package), quantity: 1)
      out = JSON.parse(Api::V1::PackagesLocationSerializer.new(pl).as_json.to_json)
      expect(out['packages_location']['location_id']).to eq(location.id)
      expect(out['locations']).to eq([{ 'id' => location.id, 'building' => 'SER-RET', 'area' => '1' }])
    end
  end
end
