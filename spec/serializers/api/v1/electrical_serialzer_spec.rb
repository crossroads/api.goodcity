require 'rails_helper'

context Api::V1::ElectricalSerializer do

  let(:electrical)   { build(:electrical) }
  let(:serializer) { Api::V1::ElectricalSerializer.new(electrical).as_json }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    electrical.attributes.except("id").keys.each do |key|
      expect(json["electrical"]["#{key}"]).to eq(electrical.send("#{key}".to_sym))
    end
  end

  context "doesn't include country if include_country = false" do
    let(:serializer) { Api::V1::ElectricalSerializer.new(electrical, include_country: false).as_json }
    it { expect(json.keys).to_not include('country') }
  end

  context "includes country if include_country = true" do
    let(:serializer) { Api::V1::ElectricalSerializer.new(electrical, include_country: true).as_json }
    it { expect(json.keys).to_not include('country') }
  end
end
