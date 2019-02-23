require 'rails_helper'

context MessageSubscription do
  # base case - message with offer, no reviewer
  let(:message) { create :message }
  let(:reviewer) { create :user, :reviewer }

  context "subscribe_users_to_message" do
    before(:each) do
      # whitelist all other calls and just check specific expectations
      allow(message).to receive(:add_subscription)
    end
    context "should subscribe the message sender" do
      let(:user_id) { message.sender_id }
      it do
        expect(message).to receive(:add_subscription).with('read', user_id)
        message.subscribe_users_to_message
      end
    end

    context "should subscribe donor" do
      let(:user_id) { message.offer.created_by_id }
      it do
        expect(message).to receive(:add_subscription).with('unread', user_id)
        message.subscribe_users_to_message
      end
    end

    context "should subscribe users who have sent previous messages" do
      let(:user_id) { reviewer.id }
      before(:each) do
        expect(Subscription).to receive_message_chain('where.pluck').and_return([user_id])
      end
      it do
        expect(message).to receive(:add_subscription).with('unread', user_id)
        message.subscribe_users_to_message
      end
    end

    context "should subscribe admin users processing the offer" do
      before(:each) { message.offer.reviewed_by_id = reviewer.id }
      it do
        expect(message).to receive(:add_subscription).with('unread', reviewer.id)
        message.subscribe_users_to_message
      end
    end

    context "should subscribe all reviewers if donor sends messages but offer has no reviewer" do
      let!(:reviewer) { create :user, :reviewer }
      let(:offer) { create :offer }
      let(:message) { create :message, sender: offer.created_by, offer: offer }
      it do
        expect(message.offer.reviewed_by_id).to eql(nil)
        # expect(message).to receive(:add_subscription).with('read', message.offer.created_by_id)
        expect(message).to receive(:add_subscription).with('unread', reviewer.id)
        message.subscribe_users_to_message
      end
    end

    context "should not subscribe system users" do
      let(:sender) { create :user, :system }
      before(:each) { allow(message).to receive(:sender_id).and_return(sender.id) }
      it do
        expect(message).to_not receive(:add_subscription).with(anything, sender.id)
        message.subscribe_users_to_message
      end
    end

    context "should not subscribe donor if offer is cancelled" do
      let(:user_id) { message.offer.created_by_id }
      before(:each) { message.offer.cancel! }
      it do
        expect(message).to_not receive(:add_subscription).with(anything, user_id)
        message.subscribe_users_to_message
      end
    end

    context "private messages" do
      let(:message) { create :message, is_private: true, sender: reviewer }
      
      context "should not subscribe donor" do
        let(:user_id) { message.offer.created_by_id }
        it do
          expect(message).to_not receive(:add_subscription).with(anything, user_id)
          message.subscribe_users_to_message
        end
      end

      context "should subscribe all supervisors" do
        let!(:supervisor) { create :user, :supervisor }
        it do
          expect(message).to receive(:add_subscription).with('read', reviewer.id) # sender
          expect(message).to receive(:add_subscription).with('unread', supervisor.id) # unsubscribed supervisor
          message.subscribe_users_to_message
        end
      end

    end

  end

  context "add_subscription" do
    let(:state) { 'unread' }
    let(:user_id) { 1 }
    it "should create subscription" do
      expect(message).to receive_message_chain('subscriptions.create').with(
        state: state,
        message_id: message.id,
        offer_id: message.offer_id,
        order_id: nil,
        user_id: user_id
      )
      message.send(:add_subscription, state, user_id)
    end
  end

end