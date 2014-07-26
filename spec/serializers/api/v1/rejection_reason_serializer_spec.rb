require 'rails_helper'

describe Api::V1::RejectionReasonSerializer do

  let(:rejection_reason) { build(:rejection_reason) }

  it "creates JSON" do
    serializer = Api::V1::RejectionReasonSerializer.new(rejection_reason)
    json = JSON.parse( serializer.to_json )
    expect(json['rejection_reason']['id']).to eql(rejection_reason.id)
    expect(json['rejection_reason']['name']).to eql(rejection_reason.name)
  end

  it "translates JSON" do
    I18n.locale = 'zh-tw'
    serializer = Api::V1::RejectionReasonSerializer.new(rejection_reason)
    json = JSON.parse( serializer.to_json )
    expect(json['rejection_reason']['name']).to eql(rejection_reason.name_zh_tw)
  end

end
