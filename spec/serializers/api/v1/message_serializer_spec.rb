require "rails_helper"

describe Api::V1::MessageSerializer do

  let(:message)         { build(:message, state_value: 'read') }
  let(:serializer)      { Api::V1::MessageSerializer.new(message) }
  let(:json)            { JSON.parse( serializer.to_json ) }

  it "creates JSON" do
    expect(json["message"]["id"]).to eql(message.id)
    expect(json["message"]["body"]).to eql(message.body)
    expect(json["message"]["state"]).to eql(message.state_value)
    expect(json["message"]["is_private"]).to eql(message.is_private)
    expect(json["message"]["sender_id"]).to eql(message.sender_id)
  end
end
