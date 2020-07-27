# frozen_string_literal: true

require 'rails_helper'

module Messages
  describe Operations do
    let(:offer) { create :offer }
    let(:message) { create :message, messageable: offer }
    let!(:supervisor) { create :user, :with_can_manage_offer_messages, role_name: 'supervisor' }
    let(:reviewer) { create(:user, :with_can_manage_offer_messages, role_name: 'reviewer' ) }

    let(:offer1) { create :offer }
    let(:offer2) { create :offer }
    let(:message1) { create :message, is_private: true, sender: reviewer, messageable: offer1 }
    let(:message2) { create :message, is_private: true, sender: reviewer, messageable: offer2 }
    let(:user_id) { offer1.created_by_id }

    describe '#subscribe_users_to_message' do
      before(:each) do
        allow(message).to receive(:add_subscription)
      end

      it 'should subscribe the message sender' do
        user_id = message.sender_id
        expect(message).to receive(:add_subscription).with('read', user_id)
        message.subscribe_users_to_message
      end

      it 'should subscribe the donor' do
        user_id = offer.created_by_id
        expect(message).to receive(:add_subscription).with('unread', user_id)
        message.subscribe_users_to_message
      end

      it 'should subscribe users who have sent previous messages' do
        subs = create(:subscription, :with_offer, message: message, user_id: reviewer.id)
        subs.update(subscribable: message.messageable)

        expect(message).to receive(:add_subscription).with('unread', reviewer.id)
        message.subscribe_users_to_message
      end

      it 'should subscribe admin users processing the offer' do
        message.messageable.reviewed_by_id = reviewer.id

        expect(message).to receive(:add_subscription).with('unread', reviewer.id)
        message.subscribe_users_to_message
      end

      it 'should not subscribe system users' do
        sender = create(:user, :system)
        expect(message).not_to receive(:add_subscription).with(anything, sender.id)

        message.subscribe_users_to_message
      end

      context 'donor sends messages but offer has no reviewer' do
        let!(:reviewer) { create :user, :with_can_manage_offer_messages, role_name: 'reviewer' }
        let(:offer) { create :offer, reviewed_by_id: reviewer.id }
        let(:message) { create :message, sender: offer.created_by, messageable: offer }

        it 'should subscribe all reviewers' do
          expect(message).to receive(:add_subscription).with('read', offer.created_by_id)
          expect(message).to receive(:add_subscription).with('unread', reviewer.id)
          message.subscribe_users_to_message
        end
      end

      context 'there is no donor (i.e. an admin created the offer)' do
        let!(:reviewer) { create :user, :with_can_manage_offer_messages, role_name: 'reviewer' }
        let!(:reviewer2) { create :user, :reviewer }
        let(:offer) { create :offer, created_by_id: nil }
        let(:message) { create :message, sender: reviewer, messageable: offer }

        it 'should not subscribe all reviewers' do
          expect(message.messageable.reviewed_by_id).to eql(nil)
          expect(message).to receive(:add_subscription).with('read', reviewer.id)
          expect(message).not_to receive(:add_subscription).with('unread', reviewer2.id)
          message.subscribe_users_to_message
        end
      end

      context 'if offer is cancelled' do
        let(:user_id) { message.messageable.created_by_id }
        it 'should not subscribe donor' do
          message.messageable.cancel!
          expect(message).not_to receive(:add_subscription).with(anything, user_id)
          message.subscribe_users_to_message
        end
      end

      context 'if private messages on offer' do
        before { User.current_user = supervisor }

        before(:each) do
          allow(message1).to receive(:add_subscription)
          allow(message2).to receive(:add_subscription)
        end

        it 'should not subscribe donor' do
          expect(message1).not_to receive(:add_subscription).with(anything, user_id)
          message1.subscribe_users_to_message
        end

        context 'if first message in thread' do
          it 'should subscribe all supervisors' do
            expect(message1).to receive(:add_subscription).with('read', reviewer.id)
            expect(message1).to receive(:add_subscription).with('unread', supervisor.id)
            message1.subscribe_users_to_message
          end
        end

        it 'should not subscribe other supervisors for subsequent messages' do
          other_reviewer = create :user, :with_can_manage_offer_messages, role_name: 'reviewer'

          # The unrelated supervisor receives the first message of the thread
          expect(message1).to receive(:add_subscription).with('read', reviewer.id)
          expect(message1).to receive(:add_subscription).with('unread', supervisor.id, )
          expect(message1).to receive(:add_subscription).with('unread', other_reviewer.id, )
          message1.subscribe_users_to_message

          create :message, is_private: true, sender: reviewer, messageable: offer2
          # The unrelated supervisor doesn't receive subsequent message of the thread
          expect(message2).to receive(:add_subscription).with('read', reviewer.id)
          expect(message2).not_to receive(:add_subscription).with('unread', other_reviewer.id)
          expect(message2).not_to receive(:add_subscription).with('unread', supervisor.id)
          message2.subscribe_users_to_message
        end

        context 'message is posted something in the private thread' do
          let!(:supervisor) { create :user, :with_can_manage_offer_messages, role_name: 'supervisor' }
          before { User.current_user = supervisor }

          it 'should subscribe a supervisor for subsequent messages' do
            # The unrelated supervisor receives the first message of the thread
            expect(message1).to receive(:add_subscription).with('read', reviewer.id)
            expect(message1).to receive(:add_subscription).with('unread', supervisor.id)
            message1.subscribe_users_to_message

            # The supervisor answers on the the private thread
            create :message, sender: supervisor, messageable: offer, is_private: true

            # The supervisor receives subsequent message of the thread
            expect(message2).to receive(:add_subscription).with('read', reviewer.id)
            expect(message2).to receive(:add_subscription).with('unread', supervisor.id)
            message2.subscribe_users_to_message
          end

          it 'should subscribe a reviewer for subsequent messages' do
            other_reviewer = create(:user, :with_can_manage_offer_messages, role_name: 'reviewer')
            User.current_user = other_reviewer
            # The unrelated supervisor receives the first message of the thread
            expect(message1).to receive(:add_subscription).with('read', reviewer.id)
            expect(message1).to receive(:add_subscription).with('unread', other_reviewer.id, )
            message1.subscribe_users_to_message

            # The supervisor answers on the the private thread
            create :message, sender: other_reviewer, messageable: offer, is_private: true

            # The supervisor receives subsequent message of the thread
            expect(message2).to receive(:add_subscription).with('read', reviewer.id) # sender
            expect(message2).to receive(:add_subscription).with('unread', other_reviewer.id)
            message2.subscribe_users_to_message
          end

          context 'message mentions' do
            let!(:user1) { create(:user) }
            let!(:user2) { create(:user) }
            let(:message) { create(:message, body: "Hello [:#{user1.id}]. I need help from you and [:#{user2.id}]") }
            let(:message2) { build(:message, body: "Hello [:#{user2.id}]. I will help") }

            before(:each) do
              allow(message).to receive(:add_subscription)
              allow(message).to receive(:add_mentions_lookup)
            end

            it 'adds message subscription to mentioned users' do
              expect(message).to receive(:add_subscription).with('unread', user1.id)
              expect(message).to receive(:add_subscription).with('unread', user2.id)
              expect(message).to receive(:add_subscription).with('read', message.sender_id)

              message.subscribe_users_to_message
            end

            it 'adds lookup for the mentioned ids' do
              expect(message2).to receive(:add_mentions_lookup).with([user2.id.to_s])

              message2.set_mentioned_users
            end
          end
        end
      end

      context "private messages on order" do
        let(:order) { create :order }
        let(:message) { build :message, is_private: true, sender: reviewer, messageable: order }

        context "should not subscribe order-creator" do
          let(:user_id) { message.messageable.created_by_id }

          it do
            expect(message).to_not receive(:add_subscription).with(anything, user_id)
            message.save
          end
        end

        context "should subscribe all users with permission '' if it's the first private message of the thread" do
          let!(:order_fulfilment_user) { create :user, :with_can_manage_order_messages, role_name: "order_fulfilment" }
          let!(:order_administrator_user) { create :user, :with_can_manage_order_messages, role_name: "order_administrator" }

          before { User.current_user = order_fulfilment_user }

          it do
            expect(message).to receive(:add_subscription).with("read", reviewer.id) # sender
            expect(message).to receive(:add_subscription).with("unread", order_fulfilment_user.id) # unsubscribed order_fulfilment_user
            expect(message).to receive(:add_subscription).with("unread", order_administrator_user.id) # unsubscribed order_administrator_user
            message.save
          end
        end

      end

      context 'public thread' do
        let!(:supervisor) { create :user, :with_can_manage_offer_messages, role_name: 'supervisor' }
        before { User.current_user = supervisor }

        it 'should subscribe a supervisor for subsequent messages' do
          # The unrelated supervisor receives the first message of the thread
          expect(message1).to receive(:add_subscription).with('read', reviewer.id)
          expect(message1).to receive(:add_subscription).with('unread', supervisor.id)
          message1.subscribe_users_to_message

          # The supervisor answers on the the private thread
          create :message, sender: supervisor, messageable: message.messageable, is_private: false

          # The supervisor receives subsequent message of the thread
          expect(message2).to receive(:add_subscription).with('read', reviewer.id)
          expect(message2).to receive(:add_subscription).with('unread', supervisor.id)
          message2.subscribe_users_to_message
        end
      end
    end
  end
end
