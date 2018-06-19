require 'rails_helper'

describe Api::V1::OrganisationWithoutOrderSerializer do
  let(:organisation_without_order)   { build(:organisation) }
  let(:serializer) { Api::V1::OrganisationWithoutOrderSerializer.new(organisation_without_order) }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['organisation_without_order']['id']).to eql(organisation_without_order.id)
    expect(json['organisation_without_order']['name_en']).to eql(organisation_without_order.name_en)
    expect(json['organisation_without_order']['name_zh_tw']).to eql(organisation_without_order.name_zh_tw)
    expect(json['organisation_without_order']['description_en']).to eql(organisation_without_order.description_en)
    expect(json['organisation_without_order']['description_zh_tw']).to eql(organisation_without_order.description_zh_tw)
    expect(json['organisation_without_order']['registration']).to eql(organisation_without_order.registration)
    expect(json['organisation_without_order']['organisation_type_id']).to eql(organisation_without_order.organisation_type_id)
    expect(json['organisation_without_order']['district_id']).to eql(organisation_without_order.district_id)
    expect(json['organisation_without_order']['country_id']).to eql(organisation_without_order.country_id)
  end

  it "translates JSON" do
    I18n.locale = 'zh-tw'
    expect(json['organisation_without_order']['name_zh_tw']).to eql(organisation_without_order.name_zh_tw)
    expect(json['organisation_without_order']['description_zh_tw']).to eql(organisation_without_order.description_zh_tw)
  end
end
