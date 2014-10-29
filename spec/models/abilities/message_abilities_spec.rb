require 'rails_helper'
require 'cancan/matchers'

describe "Message abilities" do

  before { allow_any_instance_of(PushService).to receive(:update_store) }
  before { allow_any_instance_of(PushService).to receive(:send_notification) }
  subject(:ability) { Ability.new(user) }
  let(:all_actions) { [:index, :show, :create, :update, :destroy, :manage] }
  let(:sender)      { create :user }
  let(:recipient)   { create :user }
  let(:is_private)     { false }
  let(:message)     { create :message, sender: sender, recipient: recipient, is_private: is_private }

  #~ before { expect(Pusher).to receive(:trigger) }

  context "when Administrator" do
    let(:user) { create(:user, :administrator) }
    context "and message is not is_private" do
      it{ all_actions.each { |do_action| should be_able_to(do_action, message) } }
    end
    context "and message is is_private" do
      let(:is_private) { true }
      it{ all_actions.each { |do_action| should be_able_to(do_action, message) } }
    end
  end

  context "when Supervisor" do
    let(:user) { create(:user, :supervisor) }
    context "and message is not is_private" do
      let(:can)    { [:index, :show, :create, :update, :destroy] }
      let(:cannot) { [:manage] }
      it{ can.each do |do_action|
        should be_able_to(do_action, message)
      end}
      it{ cannot.each do |do_action|
        should_not be_able_to(do_action, message)
      end}
    end
    context "and message is is_private" do
      let(:is_private) { true }
      let(:can )    { [:index, :show, :create, :update, :destroy] }
      let(:cannot)  { [:manage] }
      it{ can.each do |do_action|
        should be_able_to(do_action, message)
      end}
      it{ cannot.each do |do_action|
        should_not be_able_to(do_action, message)
      end}
    end
  end

  context "when Reviewer" do
    let(:user) { create(:user, :reviewer) }
    context "and message is not is_private" do
      let(:can)    { [:index, :show, :create] }
      let(:cannot) { [:update, :destroy, :manage] }
      it{ can.each do |do_action|
        should be_able_to(do_action, message)
      end}
      it{ cannot.each do |do_action|
        should_not be_able_to(do_action, message)
      end}
    end
    context "and message is is_private" do
      let(:is_private) { true }
      let(:can)     { [:index, :show, :create] }
      let(:cannot)  { [:update, :destroy, :manage] }
      it{ can.each do |do_action|
        should be_able_to(do_action, message)
      end}
      it{ cannot.each do |do_action|
        should_not be_able_to(do_action, message)
      end}
    end
  end

  context "when Owner" do
    context "is sender" do
      let(:user)   { sender }
      context "and message is not is_private" do
        let(:can)    { [:index, :show, :create] }
        let(:cannot) { [:update, :destroy, :manage] }
        it{ can.each do |do_action|
          should be_able_to(do_action, message)
        end}
        it{ cannot.each do |do_action|
          should_not be_able_to(do_action, message)
        end}
      end
      context "and message is is_private" do
        let(:is_private) { true }
        it{ all_actions.each { |do_action| should_not be_able_to(do_action, message) } }
      end
    end
    context "is recipient" do
      let(:user)   { sender }
      context "and message is not is_private" do
        let(:can)    { [:index, :show, :create] }
        let(:cannot) { [:update, :destroy, :manage] }
        it{ can.each do |do_action|
          should be_able_to(do_action, message)
        end}
        it{ cannot.each do |do_action|
          should_not be_able_to(do_action, message)
        end}
      end
      context "and message is is_private" do
        let(:is_private) { true }
        it{ all_actions.each { |do_action| should_not be_able_to(do_action, message) } }
      end
    end
  end

  context "when not Owner" do
    let(:user)    { create :user }
    it{ all_actions.each { |do_action| should_not be_able_to(do_action, message) } }
  end

  context "when Anonymous" do
    let(:user)    { nil }
    it{ all_actions.each { |do_action| should_not be_able_to(do_action, message) } }
  end

end
