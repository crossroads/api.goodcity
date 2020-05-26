# frozen_string_literal: true

require 'rails_helper'

module Messages
  describe Operations do
    let(:offer) { create :offer }
    let(:message) { create :message, messageable: offer }
    let(:operation) { Messages::Operations.new(message: message) }
    let!(:supervisor) { create :user, :supervisor }
    let(:reviewer) { create(:user, :reviewer) }

    let(:offer1) { create :offer }
    let(:offer2) { create :offer }
    let(:message1) { create :message, is_private: true, sender: reviewer, messageable: offer1 }
    let(:message2) { create :message, is_private: true, sender: reviewer, messageable: offer2 }
    let(:user_id) { offer1.created_by_id }
    let(:op1) { Messages::Operations.new(message: message1) }
    let(:op2) { Messages::Operations.new(message: message2) }

    describe '#initialize' do
      it 'creates instance variables for message and ids' do
        expect(operation.message).to eq(message)
        expect(operation.ids).to eq([])
      end
    end

    describe '#subscribe_users_to_message' do
      before(:each) do
        allow(operation).to receive(:add_subscriber)
      end

      it 'should subscribe the message sender' do
        user_id = message.sender_id
        expect(operation).to receive(:add_subscriber).with(user_id, 'read')
        operation.subscribe_users_to_message
      end

      it 'should subscribe the donor' do
        user_id = message.messageable.created_by_id
        expect(operation).to receive(:add_subscriber).with(user_id, 'unread')
        operation.subscribe_users_to_message
      end

      it 'should subscribe users who have sent previous messages' do
        subs = create(:subscription, :with_offer, message: message, user_id: reviewer.id)
        subs.update(subscribable: message.messageable)

        expect(operation).to receive(:add_subscriber).with(reviewer.id, 'unread')
        operation.subscribe_users_to_message
      end

      it 'should subscribe admin users processing the offer' do
        message.messageable.reviewed_by_id = reviewer.id

        expect(operation).to receive(:add_subscriber).with(reviewer.id, 'unread')
        operation.subscribe_users_to_message
      end

      it 'should not subscribe system users' do
        sender = create(:user, :system)
        expect(operation).not_to receive(:add_subscriber).with(sender.id, anything)
      end

      context 'donor sends messages but offer has no reviewer' do
        let!(:reviewer) { create :user, :reviewer }
        let(:offer) { create :offer, reviewed_by_id: reviewer.id }
        let(:message) { create :message, sender: offer.created_by, messageable: offer }

        it 'should subscribe all reviewers' do
          expect(operation).to receive(:add_subscriber).with(offer.created_by_id, 'read')
          expect(operation).to receive(:add_subscriber).with(reviewer.id, 'unread')
          operation.subscribe_users_to_message
        end
      end

      context 'there is no donor (i.e. an admin created the offer)' do
        let!(:reviewer) { create :user, :reviewer }
        let!(:reviewer2) { create :user, :reviewer }
        let(:offer) { create :offer, created_by_id: nil }
        let(:message) { create :message, sender: reviewer, messageable: offer }

        it 'should not subscribe all reviewers' do
          expect(message.messageable.reviewed_by_id).to eql(nil)
          expect(operation).to receive(:add_subscriber).with(reviewer.id, 'read')
          expect(operation).not_to receive(:add_subscriber).with(reviewer2.id, 'unread')
          operation.subscribe_users_to_message
        end
      end

      context 'if offer is cancelled' do
        let(:user_id) { message.messageable.created_by_id }
        it 'should not subscribe donor' do
          message.messageable.cancel!
          expect(operation).not_to receive(:add_subscriber).with(user_id, anything)
          operation.subscribe_users_to_message
        end
      end

      context 'if private messages' do
        before { User.current_user = supervisor }

        before(:each) do
          allow(op1).to receive(:add_subscriber)
          allow(op2).to receive(:add_subscriber)
        end

        it 'should not subscribe donor' do
          expect(op1).not_to receive(:add_subscriber).with(user_id, anything)
          op1.subscribe_users_to_message
        end

        context 'if first message in thread' do
          it 'should subscribe all supervisors' do
            expect(op1).to receive(:add_subscriber).with(reviewer.id, 'read')
            expect(op1).to receive(:add_subscriber).with(supervisor.id, 'unread')
            op1.subscribe_users_to_message
          end
        end

        it 'should not subscribe other supervisors for subsequent messages' do
          other_reviewer = create :user, :reviewer

          # The unrelated supervisor receives the first message of the thread
          expect(op1).to receive(:add_subscriber).with(reviewer.id, 'read')
          expect(op1).to receive(:add_subscriber).with(supervisor.id, 'unread')
          expect(op1).to receive(:add_subscriber).with(other_reviewer.id, 'unread')
          op1.subscribe_users_to_message

          create :message, is_private: true, sender: reviewer, messageable: offer2
          # The unrelated supervisor doesn't receive subsequent message of the thread
          expect(op2).to receive(:add_subscriber).with(reviewer.id, 'read')
          expect(op2).not_to receive(:add_subscriber).with(other_reviewer.id, 'unread')
          expect(op2).not_to receive(:add_subscriber).with(supervisor.id, 'unread')
          op2.subscribe_users_to_message
        end

        context 'message is posted something in the private thread' do
          let!(:supervisor) { create :user, :supervisor }
          before { User.current_user = supervisor }

          it 'should subscribe a supervisor for subsequent messages' do
            # The unrelated supervisor receives the first message of the thread
            expect(op1).to receive(:add_subscriber).with(reviewer.id, 'read')
            expect(op1).to receive(:add_subscriber).with(supervisor.id, 'unread')
            op1.subscribe_users_to_message

            # The supervisor answers on the the private thread
            create :message, sender: supervisor, messageable: offer, is_private: true

            # The supervisor receives subsequent message of the thread
            expect(op2).to receive(:add_subscriber).with(reviewer.id, 'read')
            expect(op2).to receive(:add_subscriber).with(supervisor.id, 'unread')
            op2.subscribe_users_to_message
          end

          it 'should subscribe a reviewer for subsequent messages' do
            other_reviewer = create(:user, :reviewer)
            User.current_user = other_reviewer
            # The unrelated supervisor receives the first message of the thread
            expect(op1).to receive(:add_subscriber).with(reviewer.id,'read')
            expect(op1).to receive(:add_subscriber).with(other_reviewer.id, 'unread')
            op1.subscribe_users_to_message

            # The supervisor answers on the the private thread
            create :message, sender: other_reviewer, messageable: offer, is_private: true

            # The supervisor receives subsequent message of the thread
            expect(op2).to receive(:add_subscriber).with(reviewer.id, 'read') # sender
            expect(op2).to receive(:add_subscriber).with(other_reviewer.id, 'unread')
            op2.subscribe_users_to_message
          end
        end
      end

      context 'public thread' do
        let!(:supervisor) { create :user, :supervisor }
        before { User.current_user = supervisor }
        it 'should subscribe a supervisor for subsequent messages' do
          # The unrelated supervisor receives the first message of the thread
          expect(op1).to receive(:add_subscriber).with(reviewer.id, 'read')
          expect(op1).to receive(:add_subscriber).with(supervisor.id, 'unread')
          op1.subscribe_users_to_message

          # The supervisor answers on the the private thread
          create :message, sender: supervisor, messageable: message.offer, is_private: false

          # The supervisor receives subsequent message of the thread
          expect(op2).to receive(:add_subscriber).with(reviewer.id, 'read')
          expect(op2).to receive(:add_subscriber).with(supervisor.id, 'unread')
          op2.subscribe_users_to_message
        end
      end
    end

    describe '#handle_mentioned_users' do
      let!(:user1) { create(:user) }
      let!(:user2) { create(:user) }
      let(:message) { build(:message, body: "Hello [:#{user1.id}]. I need help from you and [:#{user2.id}]") }
      let(:operation) { Messages::Operations.new(message: message) }

      before(:each) do
        allow(operation).to receive(:add_subscriber)
      end

      it 'creates a message lookup if any user is mentioned' do
        operation.handle_mentioned_users
        expect(message.reload.lookup).to include({ 'type' => 'User', 'id' => user1.id.to_s, 'display_name' => user1.full_name }, {'type' => "User", 'id' => user2.id.to_s, 'display_name' => user2.full_name })
      end

      it 'adds message subscription to mentioned users' do
        expect(operation).to receive(:add_subscriber).with(user1.id.to_s, 'unread')
        expect(operation).to receive(:add_subscriber).with(user2.id.to_s, 'unread')

        operation.handle_mentioned_users
      end

      context 'when no user is mentioned' do
        let!(:message) { create(:message, body: 'Hi. I need to place an order') }
        let(:operation) { Messages::Operations.new(message: message) }

        before(:each) do
          allow(operation).to receive(:add_subscriber)
        end

        it 'does not create a message lookup' do
          operation.handle_mentioned_users
          expect(message.reload.lookup).to be_nil
        end

        it 'does not add any subscribers' do
          expect(operation).not_to receive(:add_subscriber).with(anything, anything)

          operation.handle_mentioned_users
        end
      end
    end
  end
end
