require 'rails_helper'

describe Api::V1::VersionSerializer do
  let(:object_changes) { {"state"=>["draft", "submitted"]} }
  let(:version)   { build(:version, :with_item, :related_offer, object_changes: object_changes) }
  let(:serializer) { Api::V1::VersionSerializer.new(version) }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json["version"]["state"]).to eql("submitted")
  end
end
