require "rails_helper"

describe Api::V1::OrganisationsUserSerializer do
  let(:organisations_user) { build(:organisations_user) }
  let(:serializer) { Api::V1::OrganisationsUserSerializer.new(organisations_user).as_json }
  let(:json) { JSON.parse(serializer.to_json) }

  it "creates JSON" do
    expect(json["organisations_user"]["id"]).to eql(organisations_user.id)
    expect(json["organisations_user"]["user_id"]).to eql(organisations_user.user_id)
    expect(json["organisations_user"]["organisation_id"]).to eql(organisations_user.organisation_id)
    expect(json["organisations_user"]["position"]).to eql(organisations_user.position)
    expect(json["organisations_user"]["preferred_contact_number"]).to eql(organisations_user.preferred_contact_number)
  end
end
