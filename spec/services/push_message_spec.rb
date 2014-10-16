require 'rails_helper'

describe PushMessage do

  let(:message) { create :message}
  let(:serialized_message) {Api::V1::MessageSerializer.new(message)}
  let(:list_of_users) {create_list(:user,2)}
  let(:channel) {list_of_users.collect{|k| "user_#{k.id}"}}
  let(:push_message) { PushMessage.new({message: serialized_message, channel: channel})}
  let(:event) { 'update_store'}
  let(:data) {serialize(message)}

  context "initialize" do
    it do
      expect(push_message.message).to equal(serialized_message)
    end
    it do
      expect(push_message.channel).to equal(channel)
    end
  end
  describe "message" do
    it "state needs to be set" do
      message.state = "unread"
      expect(message.state).to eq("unread")
    end

    it "event needs to be set " do
      push_message.event = "update_store"
      expect(push_message.event).to eq(event)
    end

    it "should call notify" do
      expect(push_message).to receive(:notify).and_return({})
      push_message.notify
    end
  end
end
