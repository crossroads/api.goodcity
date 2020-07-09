# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

describe 'Message abilities' do
  before { allow_any_instance_of(PushService).to receive(:notify) }
  before { allow_any_instance_of(PushService).to receive(:send_notification) }
  subject(:ability) { Ability.new(user) }
  let(:all_actions) { %i[index show create update destroy manage] }
  let(:sender)      { create :user }
  let(:charity) { create(:user, :with_multiple_roles_and_permissions, roles_and_permissions: {'Charity' => ['can_login_to_browse']}) }
  let(:is_private) { false }
  let(:offer) { create(:offer, created_by: user) }
  let(:message) { create :message, messageable: offer, is_private: is_private }

  context 'when Supervisor or Reviewer' do
    let(:user) { create(:user, :with_multiple_roles_and_permissions, roles_and_permissions: {'Supervisor' => ['can_manage_offer_messages']}) }

    context 'and message is not is_private' do
      @can = %i[index show create]
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
      @can = %i[index show create]
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
    let(:offer) { create :offer, created_by: sender}
    let!(:message) { create :message, is_private: is_private, messageable: offer }
    let(:user) { sender }

    @can = %i[index show create]
    @cannot = %i[update destroy manage]

    @can.map do |action|
      it "is allowed to #{action} any non-private message that is on an offer created by them" do
        is_expected.to be_able_to(action, message)
      end
    end

    @cannot.map do |action|
      it "is not allowed to #{action}" do
        is_expected.to_not be_able_to(action, message)
      end
    end

    context 'when donor recieves a message from a reviewer' do
      let(:reviewer) { create(:user, :reviewer) }
      let(:message) { create :message, is_private: is_private, messageable: offer, sender: reviewer }
      let!(:subscription) { create :subscription, subscribable: offer, message: message }
      it 'should be able to read the message' do
        is_expected.to be_able_to(:show, message)
      end

      it 'should be able to mark_read' do
        is_expected.to be_able_to(:mark_read, message)
      end
    end

    context 'private_message' do
      let(:is_private) { true }
      it 'is not allowed to do any action' do
        all_actions.map { |action| is_expected.to_not be_able_to(action, message) }
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
    let!(:order) { create :order, created_by: charity }
    let!(:message) { create :message, is_private: is_private, messageable: order }
    let(:user) { charity }

    @can = %i[index show create]
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

    context 'when charity user recieves a message from a order admin' do
      let(:order_administrator) { create(:user, :order_administrator) }
      let(:message) { create :message, is_private: is_private, messageable: order, sender: order_administrator }
      let!(:subscription) { create :subscription, user: order_administrator, subscribable: order, message: message }
      it 'should be able to read the message' do
        is_expected.to be_able_to(:show, message)
      end

      it 'should be able to mark_read' do
        is_expected.to be_able_to(:mark_read, message)
      end
    end

    context 'private_message' do
      let(:is_private) { true }
      it 'is not allowed do any action' do
        all_actions.map { |action| is_expected.to_not be_able_to(action, message) }
      end
    end

    context 'order belonging to different user' do
      let(:is_private) { false }
      let(:message) { create :message, is_private: is_private, messageable: create(:order, created_by: create(:user)) }
      it 'is not allowed do any action' do
        all_actions.map { |action| is_expected.to_not be_able_to(action, message) }
      end
    end
  end

  context 'Order Administrator/fulfilment' do
    let(:order) { create :order, created_by: charity }
    let(:message) { create :message, is_private: is_private, messageable: order }
    let(:user) { create(:user, :with_multiple_roles_and_permissions, roles_and_permissions: {'Order administrator' => ['can_manage_order_messages']}) }

    @can = %i[index show create]
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
      @can = %i[index show create]
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
