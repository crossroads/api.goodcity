require 'rails_helper'

describe Api::V1::RejectionReasonSerializer do

  let(:rejection_reason) { build(:rejection_reason) }
  let(:serializer) { Api::V1::RejectionReasonSerializer.new(rejection_reason).as_json }
  let(:json)       { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json['rejection_reason']['id']).to eql(rejection_reason.id)
    expect(json['rejection_reason']['name']).to eql(rejection_reason.name)
  end

  it "translates JSON" do
    in_locale 'zh-tw' do
      json = JSON.parse( serializer.to_json )
      expect(json['rejection_reason']['name']).to eql(rejection_reason.name_zh_tw)
    end
  end

end
