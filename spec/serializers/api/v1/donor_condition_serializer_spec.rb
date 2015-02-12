require 'rails_helper'

describe Api::V1::DonorConditionSerializer do

  let(:donor_condition) { build(:donor_condition) }
  let(:serializer)      { Api::V1::DonorConditionSerializer.new(donor_condition) }
  let(:json)            { JSON.parse( serializer.to_json ) }

  it_behaves_like 'name_with_language'

  it "creates JSON" do
    expect(json['donor_condition']['id']).to eql(donor_condition.id)
    expect(json['donor_condition']['name']).to eql(donor_condition.name)
  end

  it "translates JSON" do
    I18n.locale = 'zh-tw'
    expect(json['donor_condition']['name']).to eql(donor_condition.name_zh_tw)
  end

end
