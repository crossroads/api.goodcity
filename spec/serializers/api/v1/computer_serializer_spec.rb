require 'rails_helper'

context Api::V1::ComputerSerializer do

  let(:computer)   { build(:computer) }
  let(:serializer) { Api::V1::ComputerSerializer.new(computer).as_json }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    computer.attributes.except("id").keys.each do |key|
      expect(json["computer"]["#{key}"]).to eq(computer.send("#{key}".to_sym))
    end
  end

  context "doesn't include country if include_country = false" do
    let(:serializer) { Api::V1::ComputerSerializer.new(computer, include_country: false).as_json }
    it { expect(json.keys).to_not include('country') }
  end

  context "includes country if include_country = true" do
    let(:serializer) { Api::V1::ComputerSerializer.new(computer, include_country: true).as_json }
    it { expect(json.keys).to_not include('country') }
  end
end
