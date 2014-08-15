require 'rails_helper'
require 'cancan/matchers'

describe "Message abilities" do

  subject(:ability) { Ability.new(user) }
  let(:all_actions) { [:index, :show, :create, :update, :destroy, :manage] }
  let(:sender)      { create :user }
  let(:recipient)   { create :offer }
  let(:private)     { false }
  let(:message)     { create :message, sender: sender, recipient: recipient, private: private }

  context "when Administrator" do
    let(:user) { create :administrator }
    context "and message is not private" do
      it{ all_actions.each { |do_action| should be_able_to(do_action, message) } }
    end
    context "and message is private" do
      let(:private) { true }
      it{ all_actions.each { |do_action| should be_able_to(do_action, message) } }
    end
  end

  context "when Supervisor" do
    let(:user) { create :supervisor }
    context "and message is not private" do
      let(:can)    { [:index, :show, :create, :update, :destroy] }
      let(:cannot) { [:manage] }
      it{ can.each do |do_action|
        should be_able_to(do_action, message)
      end}
      it{ cannot.each do |do_action|
        should_not be_able_to(do_action, message)
      end}
    end
    context "and message is private" do
      let(:private) { true }
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
    let(:user) { create :reviewer }
    context "and message is not private" do
      let(:can)    { [:index, :show, :create] }
      let(:cannot) { [:update, :destroy, :manage] }
      it{ can.each do |do_action|
        should be_able_to(do_action, message)
      end}
      it{ cannot.each do |do_action|
        should_not be_able_to(do_action, message)
      end}
    end
    context "and message is private" do
      let(:private) { true }
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
      context "and message is not private" do
        let(:can)    { [:index, :show, :create] }
        let(:cannot) { [:update, :destroy, :manage] }
        it{ can.each do |do_action|
          should be_able_to(do_action, message)
        end}
        it{ cannot.each do |do_action|
          should_not be_able_to(do_action, message)
        end}
      end
      context "and message is private" do
        let(:private) { true }
        it{ all_actions.each { |do_action| should_not be_able_to(do_action, message) } }
      end
    end
    context "owns the recipient offer" do
      let(:user)      { create :user }
      let(:recipient) { create :offer, created_by: user }
      context "and message is not private" do
        let(:can)    { [:index, :show, :create] }
        let(:cannot) { [:update, :destroy, :manage] }
        it{ can.each do |do_action|
          should be_able_to(do_action, message)
        end}
        it{ cannot.each do |do_action|
          should_not be_able_to(do_action, message)
        end}
      end
      context "and message is private" do
        let(:private) { true }
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
