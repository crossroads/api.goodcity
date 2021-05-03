require "rails_helper"

describe Api::V1::NotificationSerializer do

  let(:user) { create(:user) }
  let(:offer)  { create(:offer) }
  let!(:shareable) { create :shareable, resource: offer }
  let(:package) { create :package }
  let(:message) { create :message, messageable: offer, is_private: true }
  let(:message2) { create :message, messageable: offer, is_private: true }
  let(:serializer) { Api::V1::NotificationSerializer.new(message, root: "message").as_json }
  let(:json) { JSON.parse(serializer.to_json) }

  before do
    User.current_user = user
    create(:subscription, user: user, message: message)
    create(:subscription, user: user, message: message2)
  end

  it "creates JSON" do
    expect(json["message"]["id"]).to eql(message.id)
    expect(json["message"]["body"]).to eql(message.body)
    expect(json["message"]["state"]).to eql(message.state_value)
    expect(json["message"]["is_private"]).to eql(message.is_private)
    expect(json["message"]["sender_id"]).to eql(message.sender_id)
    expect(json["message"]["unread_count"]).to eql(2)
    expect(json["message"]["shareable_public_id"]).to eql(shareable.public_uid)
  end
end
