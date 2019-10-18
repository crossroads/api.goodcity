require 'rails_helper'

context Api::V1::ComputerAccessorySerializer do

  let(:computer_accessory)   { build(:computer_accessory) }
  let(:serializer) { Api::V1::ComputerAccessorySerializer.new(computer_accessory).as_json }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    computer_accessory.attributes.except("id").keys.each do |key|
      expect(json["computer_accessory"]["#{key}"]).to eq(computer_accessory.send("#{key}".to_sym))
    end
  end

  context "doesn't include country if include_country = false" do
    let(:serializer) { Api::V1::ComputerAccessorySerializer.new(computer_accessory, include_country: false).as_json }
    it { expect(json.keys).to_not include('country') }
  end

  context "includes country if include_country = true" do
    let(:serializer) { Api::V1::ComputerAccessorySerializer.new(computer_accessory, include_country: true).as_json }
    it { expect(json.keys).to_not include('country') }
  end
end
