# frozen_string_literal: true

require 'rails_helper'

module Messages
  describe Operations do
    let(:message) { create :message, messageable: create(:offer) }
    let(:operation) { Messages::Operations.new(message: message) }
    let(:reviewer) { create(:user, :reviewer) }

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
        let(:offer) { create :offer }
        let(:message) { build :message, is_private: true, sender: reviewer, messageable: offer }
        let(:message2) { build :message, is_private: true, sender: reviewer, messageable: offer }
        let(:user_id) { offer.created_by_id }

        it 'should not subscribe donor' do
          expect(operation).not_to receive(:add_subscriber).with(user_id, anything)
          operation.subscribe_users_to_message
        end

        # context 'if first message in thread' do
        #   let!(:supervisor) { create :user, :supervisor }
        # end
      end
    end
  end
end
