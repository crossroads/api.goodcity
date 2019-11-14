require "rails_helper"

context Api::V1::LookupSerializer do
  let(:lookup) { build(:lookup) }
  let(:serializer) { Api::V1::LookupSerializer.new(lookup).as_json }
  let(:json) { JSON.parse(serializer.to_json) }

  it "creates JSON" do
    lookup.attributes.except("id").keys.each do |key|
      expect(json["lookup"]["#{key}"]).to eq(lookup.send("#{key}".to_sym))
    end
  end
end
