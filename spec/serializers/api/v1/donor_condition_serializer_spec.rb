require 'rails_helper'

describe Api::V1::DonorConditionSerializer do

  let(:donor_condition) { build(:donor_condition) }
  let(:serializer)      { Api::V1::DonorConditionSerializer.new(donor_condition).as_json }
  let(:json)            { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['donor_condition']['id']).to eql(donor_condition.id)
    expect(json['donor_condition']['name']).to eql(donor_condition.name)
    expect(json['donor_condition']['visible_to_donor']).to eql(donor_condition.visible_to_donor)
  end

  it "translates JSON" do
    in_locale 'zh-tw' do
      expect(json['donor_condition']['name']).to eql(donor_condition.name_zh_tw)
    end
  end

end
