require "rails_helper"

describe Message, type: :model do

  before { allow_any_instance_of(PushService).to receive(:update_store) }
  before { allow_any_instance_of(PushService).to receive(:send_notification) }
  let(:donor) { create :user }
  let(:reviewer) { create :user, :reviewer }
  let(:offer) { create :offer, created_by_id: donor.id }
  let(:item)  { create :item, offer_id: offer.id }

  def create_message(options = {})
    options = { sender_id: donor.id, offer_id: offer.id }.merge(options)
    create :message, options
  end

  def build_message(options = {})
    options = { sender_id: donor.id, offer_id: offer.id }.merge(options)
    build :message, options
  end

  describe "Associations" do
    it { should belong_to :recipient }
    it { should belong_to :sender }
    it { should belong_to :offer }
    it { should belong_to :item }
    it { should have_many :subscriptions }
    it { should have_many :offers_subscription }
  end

  describe "current_user_messages" do
    it "returns message object with current user message state" do
      ["read", "unread"].each do |state|
        message = create_message(state: state)
        returned_message = Message.current_user_messages(donor.id, message.id)
        expect(returned_message.state).to eq(message.state)
      end
    end
  end

  describe "subscribe_users_to_message" do
    it "sender subscription state matches message state" do
      ["read", "unread"].each do |state|
        message = create_message(sender_id: donor.id, state: state)
        expect(message.subscriptions.count).to eq(1)
        expect(message.subscriptions).to include(have_attributes(user_id: donor.id, state: state))
      end
    end

    it "subscribe donor if not already subscribed to reviewer sent message" do
      expect(offer.subscriptions.count).to eq(0)
      message = create_message(sender_id: reviewer.id)
      expect(message.subscriptions.count).to eq(2)
      expect(message.subscriptions).to include(have_attributes(user_id: donor.id))
    end

    it "subscribes users to message in unread state" do
      message1 = create_message(sender_id: donor.id)
      message2 = create_message(sender_id: reviewer.id)
      expect(message2.subscriptions.count).to eq(2)
      expect(message2.subscriptions).to include(have_attributes(user_id: donor.id, state: "unread"))
    end
  end

  describe "send_new_message_notification" do
    it "notify subscribed users except sender" do
      message1 = create_message(sender_id: donor.id)
      message2 = build_message(sender_id: reviewer.id, body: "Sample message")
      expect_any_instance_of(PushService).to receive(:send_notification) do |obj, args|
        expect(args[:text]).to eq("Sample message")
        expect(args[:entity_type]).to eq("message")
        expect(args[:entity]).to eq(message2)
        expect(args[:channel]).to eq(["user_#{donor.id}"])
      end
      message2.save
    end

    it "donor is not notified for private messages" do
      supervisor = create :user, :supervisor
      message1 = create_message(sender_id: donor.id)
      message2 = create_message(sender_id: supervisor.id, is_private: true)
      message3 = build_message(sender_id: reviewer.id, is_private: true)
      expect_any_instance_of(PushService).to receive(:send_notification) do |obj, args|
        expect(args[:entity]).to eq(message3)
        expect(args[:channel]).to_not include(["user_#{donor.id}"])
      end
      message3.save
    end

    it "notify all supervisors if no supervisor is subscribed in private thread" do
      message = build_message(sender_id: reviewer.id, body: "Sample message", is_private: true)
      expect_any_instance_of(PushService).to receive(:send_notification) do |obj, args|
        expect(args[:channel]).to eq(["supervisor"])
      end
      message.save
    end
  end

  describe "update_ember_store" do
    let(:pusher) {
      pusher = PushService.new
      allow(pusher).to receive(:update_store)
      allow(pusher).to receive(:send_notification)
      pusher
    }
    it do
      unsubscribed_user = create :user, :reviewer
      subscribed_user = create :user, :reviewer
      create_message(sender_id: subscribed_user.id)

      message = build_message(sender_id: donor.id)
      allow(message).to receive(:service).and_return(pusher)

      #note unfortunately expect :update_store is working here based on the order it's called in code
      expect(pusher).to receive(:update_store) do |args|
        expect(args[:channel]).to eq(["user_#{subscribed_user.id}"])
        expect(args[:data][:state]).to eq("unread")
      end

      expect(pusher).to receive(:update_store) do |args|
        expect(args[:channel]).to eq(["user_#{unsubscribed_user.id}"])
        expect(args[:data][:state]).to eq("never-subscribed")
      end

      message.save
    end
  end
end
