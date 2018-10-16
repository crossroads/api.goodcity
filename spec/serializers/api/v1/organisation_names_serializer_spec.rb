require 'rails_helper'

describe Api::V1::OrganisationNamesSerializer do

  let(:organisations)   { build(:organisation) }
  let(:serializer) { Api::V1::OrganisationNamesSerializer.new(organisations).as_json }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['organisation_names']['id']).to eql(organisations.id)
    expect(json['organisation_names']['name_en']).to eql(organisations.name_en)
    expect(json['organisation_names']['name_zh_tw']).to eql(organisations.name_zh_tw)
  end
end
