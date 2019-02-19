require 'rails_helper'

context PushUpdatesForMessage do

  # Base case: reviewer1 sends message to donor
  let!(:message) { create :message, sender: reviewer1 }
  let(:donor) { message.offer.created_by }
  let(:donor_channel) { "user_#{donor.id}" }
  let(:reviewer1) { create :user, :reviewer }
  let(:reviewer1_channel) { "user_#{reviewer1.id}_admin" }
  # let(:data) { { item: item_data, sender: sender } }
  # let(:item_data) {}
  # let(:sender) { reviewer }
  let(:push_service) { PushService.new }

  before(:each) do
    allow(PushService).to receive(:new).and_return(push_service)
  end

  context "update_client_store" do

    context "should send a push update to" do

      it "message sender" do
        not_subscribed = (User.staff.to_a - [reviewer1]).flatten.uniq
        expect(message).to receive(:send_update).with('unread', [donor_channel])
        expect(message).to receive(:send_update).with('read', [reviewer1_channel])
        expect(message).to receive(:send_update).with('never-subscribed', not_subscribed)
        message.update_client_store
      end
      it "offer creator"
      it "subscribed reviewer"
      it "not-yet-subscribed reviewer"
    end

    context "should not send a push update to" do
      it "a system user"
      it "a donor when message is private"
      it "a donor when offer is cancelled"
    end

    context "should group channels together by state"

    it "with more detailed sender info"

  end

  context "send_update" do
    let(:state) { 'unread' }
    let(:test_channels) { 'test_channel' }
    it do
      expect(push_service).to receive(:send_update_store) do |channels, app_name, data|
        expect(channels).to eql(test_channels)
        # expect(data[:sender].attributes[:id]).to eq(reviewer.id)
        expect(data[:operation]).to eql(:create)
      end
      message.send(:send_update, state, test_channels)
    end
  end

  context "app_name_for_user" do
  end

  context "state_for_user" do
  end

  context "notify_deletion_to_subscribers" do
    it "should send delete push update to all admins"
    it "should not send delete push update to offer donor"
  end

end