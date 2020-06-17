# frozen_string_literal: true

require 'rails_helper'
require 'cancan/matchers'

describe 'Message abilities' do
  before { allow_any_instance_of(PushService).to receive(:notify) }
  before { allow_any_instance_of(PushService).to receive(:send_notification) }
  subject(:ability) { Ability.new(user) }
  let(:all_actions) { %i[index show create update destroy manage] }
  let(:sender)      { create :user }
  let(:charity) { create :user, :charity }
  let(:is_private) { false }
  let(:message) { create :message, is_private: is_private }

  context 'when Administrator' do
    let(:user) { create(:user, :administrator) }
    context 'and message is not is_private' do
      it { all_actions.each { |do_action| is_expected.to be_able_to(do_action, message) } }
    end
    context 'and message is is_private' do
      let(:is_private) { true }
      it { all_actions.each { |do_action| is_expected.to be_able_to(do_action, message) } }
    end
  end

  context 'when Supervisor' do
    let(:user) { create(:user, :with_can_manage_messages_permission, role_name: 'Supervisor') }

    context 'and message is not is_private' do
      @can = %i[index show create update destroy]
      @cannot = %i[manage]

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
      let(:message) { create :message, is_private: true }
      @can = %i[index show create update destroy]
      @cannot = %i[manage]

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

  context 'when Reviewer' do
    let(:user) { create(:user, :with_can_create_and_read_messages_permission, role_name: 'Reviewer') }
    context 'and message is not is_private' do
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

    context 'and message is is_private' do
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

  context 'when Donor' do
    let(:offer) { create :offer, created_by: sender}
    let(:message) { create :message, is_private: is_private, messageable: offer }
    let(:user)   { sender }

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

    context 'private_message' do
      let(:is_private) { true }
      [@can, @cannot].flatten do |action|
        it "is not allowed to #{action}" do
          is_expected.to_not be_able_to(action, message)
        end
      end
    end

    context 'offer belonging to different user' do
      let(:is_private) { false }
      let(:message) { create :message, is_private: is_private, messageable: create(:offer, created_by: create(:user)) }
      [@can, @cannot].flatten do |action|
        it "is not allowed to #{action}" do
          is_expected.to_not be_able_to(action, message)
        end
      end
    end
  end

  context 'Charity user' do
    let(:order) { create :order, created_by: charity }
    let(:message) { create :message, is_private: is_private, messageable: order }
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

    context 'private_message' do
      let(:is_private) { true }
      [@can, @cannot].flatten do |action|
        it "is not allowed to #{action}" do
          is_expected.to_not be_able_to(action, message)
        end
      end
    end

    context 'order belonging to different user' do
      let(:is_private) { false }
      let(:message) { create :message, is_private: is_private, messageable: create(:order, created_by: create(:user)) }
      [@can, @cannot].flatten do |action|
        it "is not allowed to #{action}" do
          is_expected.to_not be_able_to(action, message)
        end
      end
    end
  end

  context 'when not Owner' do
    let(:user) { create :user }
    it { all_actions.each { |do_action| is_expected.to_not be_able_to(do_action, message) } }
  end

  context 'when Anonymous' do
    let(:user) { nil }
    it { all_actions.each { |do_action| is_expected.to_not be_able_to(do_action, message) } }
  end
end
