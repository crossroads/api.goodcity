require 'rails_helper'

context PushUpdatesForMessage do

  # Base case: reviewer1 sends message to donor
  let(:charity) { create(:user, :charity) }
  let(:charity_browse_channel) { "user_#{charity.id}_browse" }
  let(:donor) { create(:user) }
  let(:offer) { create(:offer, created_by: donor) }
  let!(:message) { create :message, sender: reviewer1, messageable: offer }
  let(:donor_app_channel) { "user_#{donor.id}" }
  let(:donor_browse_channel) { "user_#{donor.id}_browse" }
  let(:reviewer1) { create :user, :with_reviewer_role, :with_can_manage_offer_messages_permission }
  let(:reviewer1_channel) { "user_#{reviewer1.id}_admin" }
  let(:push_service) { PushService.new }

  before(:each) do
    allow(PushService).to receive(:new).and_return(push_service)
  end

  context "update_client_store" do

    context "when reviewer1 sends a message on an offer to the donor's channel" do
      let!(:message) { create :message, sender: reviewer1, messageable: offer, recipient: donor }
      let!(:reviewer2) { create :user, :with_reviewer_role, :with_can_manage_offer_messages_permission } # create this user but don't use it
      let(:reviewer2_channel) { "user_#{reviewer2.id}_admin" }
      
      it "should send a push update to donor, message sender / offer reviewer, other reviewers" do
        expect(message).to receive(:send_update).with('unread', [donor_app_channel, donor_browse_channel])
        expect(message).to receive(:send_update).with('read', [reviewer1_channel])
        expect(message).to receive(:send_update).with('never-subscribed', [reviewer2_channel])
        message.update_client_store
      end

      it "should no send a push update to a charity" do
        expect(message).not_to receive(:send_update).with(anything, array_including(charity_browse_channel))
        message.update_client_store
      end
    end

    context "when reviewer1 sends a message to a charity about an offer" do
      let!(:message) { create :message, sender: reviewer1, messageable: offer, recipient: charity }
      let!(:reviewer2) { create :user, :with_reviewer_role, :with_can_manage_offer_messages_permission } # create this user but don't use it
      let(:reviewer2_channel) { "user_#{reviewer2.id}_admin" }
      
      it "should send a push update to charity, message sender / offer reviewer, other reviewers" do
        expect(message).to receive(:send_update).with('unread', [charity_browse_channel])
        expect(message).to receive(:send_update).with('read', [reviewer1_channel])
        expect(message).to receive(:send_update).with('never-subscribed', [reviewer2_channel])
        message.update_client_store
      end

      it "should no send a push update to donor" do
        expect(message).not_to receive(:send_update).with(anything, array_including(donor_browse_channel))
        message.update_client_store
      end
    end

    context "when order_fulfilment1 sends a message on an order to charity channel" do
      let(:order) { create :order, created_by: charity }
      let(:order_fulfilment1) { create :user, :with_order_fulfilment_role, :with_can_manage_order_messages_permission }
      let(:order_fulfilment1_channel) { "user_#{order_fulfilment1.id}_stock" }
      let!(:message) { create :message, sender: order_fulfilment1, messageable: order }
      let!(:order_fulfilment2) { create :user, :with_order_fulfilment_role, :with_can_manage_order_messages_permission } # create this user but don't use it
      let(:order_fulfilment2_channel) { "user_#{order_fulfilment2.id}_stock" }
      it "should send a push update to order recipicharityent, order_fulfilment1 and order_fulfilment2" do
        expect(message).to receive(:send_update).with('unread', [charity_browse_channel])
        expect(message).to receive(:send_update).with('read', [order_fulfilment1_channel])
        expect(message).to receive(:send_update).with('never-subscribed', [order_fulfilment2_channel])
        message.update_client_store
      end
    end

    context "should not send a push update to" do
      it "a system user" do
        create(:user, :system) # create this user and subscribe them just to really be sure
        expect(message).to receive(:send_update).with('unread', [donor_app_channel, donor_browse_channel])
        expect(message).to receive(:send_update).with('read', [reviewer1_channel])
        message.update_client_store
      end
      it "a donor when message is private" do
        message.is_private = true
        expect(message).to_not receive(:send_update).with('unread', [donor_app_channel, donor_browse_channel])
        expect(message).to receive(:send_update).with('read', [reviewer1_channel])
        message.update_client_store
      end
      it "a donor when offer is cancelled" do
        message.messageable.cancel!
        expect(message).to_not receive(:send_update).with('unread', [donor_app_channel, donor_browse_channel])
        expect(message).to receive(:send_update).with('read', [reviewer1_channel])
        message.update_client_store
      end
    end

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
    let(:reviewer2) { create :user, :reviewer }
    let(:reviewer2_channel) { "user_#{reviewer2.id}_admin" }
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

  context "app_names_for_user" do
    subject { message.send(:app_names_for_user, user_id) }
    
    context "when Order" do
      let(:message) { create :message, :with_order }
      context "creator" do
        let(:user_id) { message.messageable.created_by_id }
        it { expect(subject).to eql([BROWSE_APP]) }
      end
      context "but not creator" do
        let(:user_id) { reviewer1.id }
        it { expect(subject).to eql([STOCK_APP]) }
      end
    end

    context "when Offer" do
      context "creator" do
        let(:user_id) { message.messageable.created_by_id }
        it { expect(subject).to eql([DONOR_APP, BROWSE_APP]) }
      end
      context "but not creator" do
        let(:user_id) { reviewer1.id }
        it { expect(subject).to eql([ADMIN_APP]) }
      end
    end
  end

  context "serialized_user" do
    it "UserSerializer should only send summary info (no email or mobile)" do
      expect(Api::V1::UserSerializer).to receive(:new).with(donor, user_summary: true)
      message.send(:serialized_user, donor)
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

  context "relevant_staff_user_ids" do
    let!(:reviewer1) { create :user, :with_reviewer_role, :with_can_manage_offer_messages_permission }
    let!(:order_fulfilment1) { create :user, :with_order_fulfilment_role, :with_can_manage_order_messages_permission }

    context "should search for 'can_manage_offer_messages' permission" do
      let(:message) { create :message, messageable: create(:offer) }
      it { expect(message.send(:relevant_staff_user_ids)).to eql([reviewer1.id]) }
    end
    context "should search for 'can_manage_order_messages' permission" do
      let(:message) { create :message, messageable: create(:order) }
      it { expect(message.send(:relevant_staff_user_ids)).to eql([order_fulfilment1.id]) }
    end
  end

end
