# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

describe 'Message abilities' do
  before { allow_any_instance_of(PushService).to receive(:notify) }
  before { allow_any_instance_of(PushService).to receive(:send_notification) }
  subject(:ability) { Api::V1::Ability.new(user) }
  let(:all_actions) { %i[index show create update destroy manage notifications] }
  let(:sender)      { create :user }
  let(:charity) { create(:user, :charity) }
  let(:reviewer) { create(:user, :reviewer, :with_can_manage_offer_response_messages_permission, :with_can_manage_offer_messages_permission) }
  let(:is_private) { false }
  let(:offer) { create(:offer, created_by: user) }
  let(:offerResponse) { create(:offer_response, user_id: charity.id, offer_id: offer.id) }
  let(:message) { create :message, messageable: offer, is_private: is_private }

  context 'when Supervisor or Reviewer' do
    let(:user) { create(:user, :with_supervisor_role, :with_can_manage_offer_messages_permission, :with_can_manage_offer_messages_permission) }

    context 'and message is not is_private' do
      @can = %i[index show create notifications]
      @cannot = %i[manage update destroy]

      @can.map do |action|
        it "can do #{action}" do
          is_expected.to be_able_to(action, message)
        end
      end

      @cannot.map do |action|
        it "cannot do #{action}" do
          is_expected.to_not be_able_to(action, message)
        end
      end
    end

    context 'and message is is_private' do
      let(:message) { create :message, is_private: true, messageable: offer }
      @can = %i[index show create notifications]
      @cannot = %i[manage update destroy]

      @can.map do |action|
        it "can do #{action}" do
          is_expected.to be_able_to(action, message)
        end
      end

      @cannot.map do |action|
        it "cannot do #{action}" do
          is_expected.to_not be_able_to(action, message)
        end
      end
    end
  end

  context 'when Donor' do
    let(:user) { sender }
    let(:offer) { create :offer, created_by: sender }
    let(:other_offer) { create :offer, created_by: sender }
    let!(:message) { create :message, sender: reviewer, is_private: is_private, messageable: offer }
    let!(:message2) { create :message, sender: reviewer, is_private: is_private, messageable: other_offer, recipient: user }

    @can = %i[index show create notifications]
    @cannot = %i[update destroy manage]

    @can.map do |action|
      it "is allowed to #{action} any non-private message that is on an offer created by them" do
        is_expected.to be_able_to(action, message)
      end

      it "is allowed to #{action} any non-private message that has them as the recipient" do
        is_expected.to be_able_to(action, message2)
      end
    end

    @cannot.map do |action|
      it "is not allowed to #{action}" do
        is_expected.to_not be_able_to(action, message)
      end
    end

    context "when donor's offer is discussed by a charity" do
      let(:charity_user) { create(:user, :charity) }
      let(:reviewer) { create(:user, :reviewer) }
      let(:message_from_charity) { create(:message, is_private: false, messageable: offerResponse, sender: charity_user) }
      let(:message_to_charity) { create(:message, is_private: false, messageable: offerResponse, sender: reviewer, recipient: charity_user) }

      it 'should not show messages sent by a charity regarding the offer' do
        is_expected.not_to be_able_to(:show, message_from_charity)
      end

      it 'should not show notification of messages sent by a charity regarding the offer' do
        is_expected.not_to be_able_to(:notifications, message_from_charity)
      end

      it 'should not show notification of messages sent to a charity regarding the offer' do
        is_expected.not_to be_able_to(:notifications, message_to_charity)
      end

      it 'should not show messages sent to a charity regarding the offer' do
        is_expected.not_to be_able_to(:show, message_to_charity)
      end
    end

    context 'when donor recieves a message from a reviewer' do
      let!(:message) { create :message, is_private: is_private, messageable: offer, sender: reviewer }

      it 'should be able to read the message' do
        is_expected.to be_able_to(:show, message)
      end

      it 'should be able to read the notification of messages' do
        is_expected.to be_able_to(:notifications, message)
      end

      it 'should be able to mark_read' do
        is_expected.to be_able_to(:mark_read, message)
      end
    end

    context 'private_message' do
      let(:private_message) { create :message, sender: reviewer, is_private: true, messageable: offer }
      it 'is not allowed to do any action' do
        all_actions.map { |action| is_expected.to_not be_able_to(action, private_message) }
      end
    end

    context 'offer belonging to different user' do
      let(:is_private) { false }
      let(:message) { create :message, is_private: is_private, messageable: create(:offer, created_by: create(:user)) }
      it 'is not allowed to do any action' do
        all_actions.map { |action| is_expected.to_not be_able_to(action, message) }
      end
    end
  end

  context 'Charity user' do
    let(:is_private) { false }
    let(:order_fulfiller) { create(:user, :with_can_manage_order_messages_permission)}
    let(:donor) { create(:user) }
    let(:order) { create :order, created_by: charity }
    let(:offer) { create(:offer, created_by: donor) }
    let(:message) { create :message, sender: order_fulfiller, is_private: is_private, messageable: order }
    let!(:subscription) { create :subscription, message: message, subscribable: order, state: 'unread', user: charity}
    let(:user) { charity }

    @can = %i[index show create notifications]
    @cannot = %i[update destroy manage]
    @can.map do |action|
      it "is allowed to #{action} any non-private message that is on an order created by them" do
        is_expected.to be_able_to(action, message)
      end
    end

    @cannot.map do |action|
      it "is not allowed to #{action}" do
        is_expected.to_not be_able_to(action, message)
      end
    end

    context 'when charity user tries to create' do
      context 'a public message' do
        let(:message) { create(:message, messageable: offerResponse, is_private: false) }

        context 'about an record that has NOT been publicly shared' do
          it 'should succeed' do
            is_expected.not_to be_able_to(:create, message)
          end
        end

        context 'about a SHARED record' do
          before { Shareable.publish(offer) }

          it 'should fail' do
            is_expected.to be_able_to(:create, message)
          end
        end
      end

      context 'a private message' do
        let(:message) { create(:message, sender: charity, messageable: offerResponse, is_private: true) }

        before { Shareable.publish(offer) }

        it 'should fail' do
          is_expected.not_to be_able_to(:create, message)
        end
      end
    end

    context 'when charity user recieves a message from an order admin' do
      let(:order_administrator) { create(:user, :order_administrator, :with_can_manage_order_messages_permission) }
      let!(:message) { create :message, is_private: is_private, messageable: order, sender: order_administrator }

      it 'should be able to read the notification of messages' do
        is_expected.to be_able_to(:notifications, message)
      end


      it 'should be able to read the message' do
        is_expected.to be_able_to(:show, message)
      end

      it 'should be able to mark_read' do
        is_expected.to be_able_to(:mark_read, message)
      end
    end

    context 'when a charity user recieves a public message from a reviewer regarding an offer' do
      let(:reviewer) { create(:user, :reviewer, :with_can_manage_offer_messages_permission) }
      let!(:message) { create :message, is_private: false, messageable: offer, sender: reviewer, recipient: user }
      let!(:message_to_donor) { create :message, is_private: false, messageable: offer, sender: reviewer, recipient: offer.created_by }
      let!(:message_from_donor) { create :message, is_private: false, messageable: offer, sender: offer.created_by }

      it 'should be able to read the message' do
        is_expected.to be_able_to(:show, message)
      end

      it 'should be able to read the notification of messages' do
        is_expected.to be_able_to(:notifications, message)
      end

      it 'should be able to mark_read' do
        is_expected.to be_able_to(:mark_read, message)
      end

      it 'should be able to read a message to the donor' do
        is_expected.not_to be_able_to(:show, message_to_donor)
      end

      it 'should be able to read a message by the donor' do
        is_expected.not_to be_able_to(:show, message_from_donor)
      end
    end

    context 'private_message' do
      let(:is_private) { true }
      let!(:message) { create :message, is_private: is_private, messageable: order }
      let!(:subscription) { } # nil, Charity doesn't get subscribed to private messages
      it 'is not allowed do any action' do
        all_actions.map { |action| is_expected.to_not be_able_to(action, message) }
      end
    end

    context 'order belonging to different user' do
      let(:is_private) { false }
      let(:user_2) { create(:user) }
      let(:order_2) { create(:order, created_by: user_2) }
      let(:message) { create :message, is_private: is_private, messageable: order_2 }
      let!(:subscription) { create :subscription, user: user_2, subscribable: order_2 }
      it 'is not allowed do any action' do
        all_actions.map { |action| is_expected.to_not be_able_to(action, message) }
      end
    end
  end

  context 'Order Administrator/fulfilment' do
    let(:order) { create :order, created_by: charity }
    let(:message) { create :message, is_private: is_private, messageable: order }
    let(:user) { create(:user, :with_order_administrator_role, :with_can_manage_order_messages_permission) }

    @can = %i[index show create notifications]
    @cannot = %i[update destroy manage]

    @can.map do |action|
      it "can do #{action}" do
        is_expected.to be_able_to(action, message)
      end
    end

    @cannot.map do |action|
      it "cannot do #{action}" do
        is_expected.to_not be_able_to(action, message)
      end
    end

    context 'private_message' do
      let(:is_private) { true }
      @can = %i[index show create notifications]
      @cannot = %i[update destroy manage]

      @can.map do |action|
        it "can do #{action}" do
          is_expected.to be_able_to(action, message)
        end
      end

      @cannot.map do |action|
        it "cannot do #{action}" do
          is_expected.to_not be_able_to(action, message)
        end
      end
    end
  end

  context 'mark messages' do
    let(:user) { create :user }
    let(:user2) { create :user }
    let(:offer) { create :offer, created_by: user }
    let(:offer2) { create :offer, created_by: user2 }
    let(:message) { create :message, is_private: is_private, messageable: offer }
    let(:message2) { create :message, is_private: is_private, messageable: offer2 }
    let!(:subscription) { create :subscription, user: user, subscribable: offer, message: message }
    let!(:subscription_2) { create :subscription, user: user2, subscribable: offer2, message: message2 }
    context 'mark_read' do
      it 'is allowed to mark_read any subscription belonging to user' do
        is_expected.to be_able_to(:mark_read, message)
      end

      it 'is not allowed to mark_read subscriptions not belonging to user' do
        is_expected.to_not be_able_to(:mark_read, message2)
      end
    end

    context 'mark_all_read' do
      it 'is allowed to mark_all_read all subscriptions belonging to user' do
        is_expected.to be_able_to(:mark_read, message)
      end

      it 'is not allowed to mark_read subscriptions not belonging to user' do
        is_expected.to_not be_able_to(:mark_all_read, message2)
      end
    end
  end

  context 'when Anonymous' do
    let(:user) { nil }
    it { all_actions.each { |do_action| is_expected.to_not be_able_to(do_action, message) } }
  end
end
