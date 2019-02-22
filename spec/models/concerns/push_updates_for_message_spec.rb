require 'rails_helper'

context PushUpdatesForMessage do

  # Base case: reviewer1 sends message to donor
  let!(:message) { create :message, sender: reviewer1 }
  let(:donor) { message.offer.created_by }
  let(:donor_channel) { "user_#{donor.id}" }
  let(:reviewer1) { create :user, :reviewer }
  let(:reviewer1_channel) { "user_#{reviewer1.id}_admin" }
  let(:reviewer2) { create :user, :reviewer }
  let(:reviewer2_channel) { "user_#{reviewer2.id}_admin" }
  let(:system_user) { create :user, :system }
  # let(:data) { { item: item_data, sender: sender } }
  # let(:item_data) {}
  # let(:sender) { reviewer }
  let(:push_service) { PushService.new }

  before(:each) do
    allow(PushService).to receive(:new).and_return(push_service)
  end

  context "update_client_store" do

    context "should send a push update to" do

      it "donor, message sender / offer reviewer, other reviewers" do
        reviewer2 # create this user but don't use it
        expect(message).to receive(:send_update).with('unread', [donor_channel])
        expect(message).to receive(:send_update).with('read', [reviewer1_channel])
        expect(message).to receive(:send_update).with('never-subscribed', [reviewer2_channel])
        message.update_client_store
      end
    end

    context "should not send a push update to" do
      it "a system user" do 
        system_user # create this user and subscribe them just to really be sure
        expect(message).to receive(:send_update).with('unread', [donor_channel])
        expect(message).to receive(:send_update).with('read', [reviewer1_channel])
        message.update_client_store
      end
      it "a donor when message is private" do
        message.is_private = true
        expect(message).to_not receive(:send_update).with('unread', [donor_channel])
        expect(message).to receive(:send_update).with('read', [reviewer1_channel])
        message.update_client_store
      end
      it "a donor when offer is cancelled" do
        message.offer.cancel!
        expect(message).to_not receive(:send_update).with('unread', [donor_channel])
        expect(message).to receive(:send_update).with('read', [reviewer1_channel])
        message.update_client_store
      end
    end

    it "with more detailed sender info"

  end

  context "send_update" do
    let(:state) { 'unread' }
    let(:test_channels) { 'test_channel' }
    before(:each) { allow(message).to receive(:sender).and_return(reviewer1) }
    it do
      expect(push_service).to receive(:send_update_store) do |channels, data|
        expect(channels).to eql(test_channels)
        expect(data[:item].attributes[:state]).to eq(state)
        expect(data[:sender].attributes[:id]).to eq(reviewer1.id)
        expect(data[:operation]).to eql(:create)
      end
      message.send(:send_update, state, test_channels)
    end
  end

  context "state_for_user" do
    subject { message.send(:state_for_user, user_id) }
    context "when user is message sender" do
      let(:user_id) { message.sender_id }
      it { expect(subject).to eql('read') }
    end
    context "when user is subscribed" do
      let(:user_id) { reviewer2.id }
      before(:each) { allow(message).to receive(:subscribed_user_ids).and_return([reviewer2.id])}
      it { expect(subject).to eql('unread') }
    end
    context "when user is not subscribed" do
      let(:user_id) { reviewer2.id }
      it { expect(subject).to eql('never-subscribed') }
    end
  end

  context "app_name_for_user" do
    subject { message.send(:app_name_for_user, user_id) }
    context "when Order" do
      let(:message) { create :message, :with_order }
      context "creator" do
        let(:user_id) { message.order.created_by_id }
        it { expect(subject).to eql(BROWSE_APP) }
      end
      context "but not creator" do
        let(:user_id) { reviewer1.id }
        it { expect(subject).to eql(STOCK_APP) }
      end
    end
    context "when Offer" do
      context "creator" do
        let(:user_id) { message.offer.created_by_id }
        it { expect(subject).to eql(DONOR_APP) }
      end
      context "but not creator" do
        let(:user_id) { reviewer1.id }
        it { expect(subject).to eql(ADMIN_APP) }
      end
    end
  end

  context "notify_deletion_to_subscribers" do
    before(:each) do
      expect(message).to receive(:send_update).with('read', channels, :delete)
    end
    context "should send delete push update to reviewers and supervisors channels" do
      let(:message) { create :message, :with_order}
      let(:channels) { [Channel::ORDER_FULFILMENT_CHANNEL] }
      it { message.send(:notify_deletion_to_subscribers) }
    end
    context "should send delete push update to order_fullfillers channel" do
      let(:channels) { [Channel::REVIEWER_CHANNEL, Channel::SUPERVISOR_CHANNEL] }
      it { message.send(:notify_deletion_to_subscribers) }
    end
  end

end