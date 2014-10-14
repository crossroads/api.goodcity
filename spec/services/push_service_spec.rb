require 'rails_helper'
# require 'pusher'

describe PushService do
  let(:message) {create :message}
  let(:user) {create :user}
  let(:users) {create_list :user, 12}
  let(:one_channel) {"user_#{user.id}"}
  let(:multiple_channels) {users.collect{|k| "user_#{k.id}"}}
  let(:push_message) { PushMessage.new({message: message, channel: channel})}
  let(:serialized_message) {Api::V1::MessageSerializer.new(push_message)}

  describe "#notify for update store" do
    let(:event) {"update_store"}
    it "multiple receipent through pusher" do
      allow(Pusher).to receive(:trigger).with(multiple_channels, event, message).and_return({})
      expect(multiple_channels).to be_a_kind_of(Array)
      expect(multiple_channels.length).to be > 10
      Pusher.trigger(multiple_channels, event, message)
    end

    it "single receipent through pusher" do
      allow(Pusher).to receive(:trigger).with(one_channel, event, message).and_return({})
      Pusher.trigger(one_channel, event, message)
    end
  end
end
