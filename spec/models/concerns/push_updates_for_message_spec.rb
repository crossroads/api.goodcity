require 'rails_helper'

context PushUpdatesForMessage do

  let(:donor) { create :user }
  let(:reviewer) { create :user, :reviewer }
  let(:offer) { create :offer, created_by_id: donor.id }

  def create_message(options = {})
    options = { sender_id: donor.id, offer_id: offer.id }.merge(options)
    create :message, options
  end

  def build_message(options = {})
    options = { sender_id: donor.id, offer_id: offer.id }.merge(options)
    build :message, options
  end

  describe "send_new_message_notification" do
    it "notify subscribed users except sender" do
      message1 = create_message(sender_id: donor.id)
      message2 = build_message(sender_id: reviewer.id, body: "Sample message")
      expect_any_instance_of(PushService).to receive(:send_notification) do |obj, channel, app_name, data|
        expect(data[:message]).to eq("Sample message")
        expect(data[:author_id]).to eq(reviewer.id)
        expect(channel).to eq(["user_#{donor.id}"])
      end
      message2.save
    end

    it "donor is not notified for private messages" do
      supervisor = create :user, :supervisor
      message1 = create_message(sender_id: donor.id)
      message2 = create_message(sender_id: supervisor.id, is_private: true)
      message3 = build_message(sender_id: reviewer.id, is_private: true)
      expect_any_instance_of(PushService).to receive(:send_notification) do |obj, channel, app_name, data|
        expect(data[:author_id]).to eq(reviewer.id)
        expect(channel).to_not include(["user_#{donor.id}"])
      end
      message3.save
    end

    it "notify all supervisors if no supervisor is subscribed in private thread" do
      message = build_message(sender_id: reviewer.id, body: "Sample message", is_private: true)
      expect_any_instance_of(PushService).to receive(:send_notification) do |obj, channel, app_name, data|
        expect(channel).to eq("supervisor")
      end
      message.save
    end
  end

  describe "update_client_store" do
    let(:push_service) { PushService.new }
    it do
      unsubscribed_user = create :user, :reviewer
      subscribed_user = create :user, :reviewer
      create_message(sender_id: subscribed_user.id)

      message = build_message(sender_id: donor.id)
      allow(message).to receive(:service).and_return(push_service)
      
      #note unfortunately expect :update_store is working here based on the order it's called in code
      expect(message).to receive(:send_update) do |state, channel, app_name|
        expect(channel).to match_array(["user_#{donor.id}"])
        expect(state).to eq("read")
      end

      expect(message).to receive(:send_update) do |state, channel, app_name|
        expect(channel).to eq(["user_#{subscribed_user.id}_admin"])
        expect(state).to eq("unread")
      end

      expect(message).to receive(:send_update) do |state, channel, app_name|
        expect(channel).to match_array(["user_#{unsubscribed_user.id}_admin"])
        expect(state).to eq("never-subscribed")
      end

      message.update_client_store
    end
  end

  describe 'notify_deletion_to_subscribers' do
    it "should not allow donor to access private messages" do
      unsubscribed_user = create :user, :reviewer
      subscribed_user = create :user, :reviewer
      message = create_message(sender_id: subscribed_user.id)
      User.current_user = reviewer

      expect(message).to receive(:send_update) do |item, user, state, channel, app_name, operation|
        expect(channel).to include("user_#{subscribed_user.id}_admin")
        expect(channel).to include("user_#{unsubscribed_user.id}_admin")
        expect(channel).to_not include("user_#{donor.id}")
        expect(operation).to eq(:delete)
      end

      message.destroy
    end
  end

end