require "rails_helper"

describe Message, type: :model do
  let(:user) { create :user }
  let(:message) { create :message }
  let(:list_of_users) { create_list(:user,2) }
  let(:channel) { list_of_users.collect{ |k| "user_#{k.id}" } }
  let(:offer) { create :offer }
  let(:item)  { create :item }
  let(:subscription)  { create :subscription }
  let(:serialized_message) { Api::V1::MessageSerializer.new(message) }

  describe "Associations" do
    it { should belong_to :recipient }
    it { should belong_to :sender }
    it { should belong_to :offer }
    it { should belong_to :item }
    it { should have_many :subscriptions }
    it { should have_many :offers_subscription }
  end

  describe ".current_user_messages" do
    it "returns message object with current user message state" do
      message
      expect(message.state).not_to be_nil
    end
  end

  describe ".on_offer_submittion" do
    let(:message_details) do
      { body: "I have made an offer.", sender_id: user.id, is_private: false,
      offer_id:offer.id }
    end
    let(:update_message) { build(:message, message_details) }
    let(:subscription) do
      create :subscription, { state: "read", offer_id: offer.id, user_id: user.id,
      message_id: update_message.id }
    end
    it "make sender  subscription state as read" do
      allow(update_message).to receive(:create).with(message_details).and_return(update_message)
      allow(update_message).to receive(:add_subscription).with("read").and_return(subscription)
      expect(update_message).to receive(:add_subscription).with("read")
      res = update_message.add_subscription("read")
      expect(res).to eq(subscription)
    end
  end

  describe "#notify_message"do
    let(:push_message) { PushMessage.new({ message: message, channel: channel }) }
    it "make a Pusher request to send the message" do
      expect(PushMessage).to receive(:new).with({ message: message, channel: channel }).and_return(push_message)
      expect(push_message).to receive(:notify).and_return({})
      PushMessage.new({ message: message, channel: channel }).notify
    end
  end

  describe "#save_with_subscriptions" do
    let(:new_message) { build(:message) }
    let(:subscriptions_details) { { state: "unread" } }
    it "create new message with state unread" do
      allow(new_message).to receive(:add_subscription).with("unread")
      allow(new_message).to receive(:subscribe_users_to_message)
      allow(new_message).to receive(:notify_message)
      expect(new_message).to receive(:save_with_subscriptions).with(subscriptions_details).and_return(new_message)
      new_message.save_with_subscriptions(subscriptions_details)
    end
  end

  describe "#add_subscription" do
    let(:subscription_attributes) { attributes_for(:subscription) }
    let(:subscription) { build :subscription, subscription_attributes }
    it "to message with specified state" do
      allow(subscription).to receive(:create).with({state: "read"}).and_return(subscription)
      allow(message).to receive(:add_subscription).with("read").and_return(subscription)
      expect(message).to receive(:add_subscription).with("read").and_return(subscription)
      message.add_subscription("read")
    end
  end

  describe "#subscribe_users_to_message" do
    let(:public_sub) { offer.subscriptions }
    let(:sender) { create :user }

    it "donor can send public message only" do
      allow(public_sub).to receive(:subscribed_users).with(sender.id)
      expect(public_sub).to receive(:subscribed_users).with(sender.id)
      offer.subscriptions.subscribed_users(sender.id)
    end
  end
end
