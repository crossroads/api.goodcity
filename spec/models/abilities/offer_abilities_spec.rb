require 'rails_helper'
require 'cancan/matchers'

describe "Offer abilities" do

  before { allow_any_instance_of(PushService).to receive(:update_store) }
  before { allow_any_instance_of(PushService).to receive(:send_notification) }
  subject(:ability) { Ability.new(user) }
  let(:all_actions) { [:index, :show, :create, :update, :destroy, :manage] }

  context "when Administrator" do
    let(:user)    { create(:user, :administrator) }
    let(:offer)     { create :offer }
    it{ all_actions.each { |do_action| should be_able_to(do_action, offer) } }
  end

  context "when Supervisor" do
    let(:user)    { create(:user, :supervisor) }
    context "and offer is draft" do
      let(:offer)     { create :offer, state: 'draft' }
      let(:can)       { [:index, :show, :create, :update, :destroy] }
      let(:cannot)    { [:manage] }
      it{ can.each do |do_action|
        should be_able_to(do_action, offer)
      end}
      it{ cannot.each do |do_action|
        should_not be_able_to(do_action, offer)
      end}
    end
  end

  context "when Reviewer" do
    let(:user)      { create(:user, :reviewer) }

    context "and offer is draft" do
      let(:offer)     { create :offer, state: 'draft' }
      let(:can)       { [:index, :show, :create, :update, :destroy] }
      let(:cannot)    { [:manage] }
      it{ can.each do |do_action|
        should be_able_to(do_action, offer)
      end}
      it{ cannot.each do |do_action|
        should_not be_able_to(do_action, offer)
      end}
    end

    context "and offer is submitted" do
      let(:offer)     { create :offer, state: 'submitted', created_by: create(:user) }
      let(:can)       { [:index, :show, :create, :update] }
      let(:cannot)    { [:destroy, :manage] }
      it{ can.each do |do_action|
        should be_able_to(do_action, offer)
      end}
      it{ cannot.each do |do_action|
        should_not be_able_to(do_action, offer)
      end}
    end
  end

  context "when Owner" do
    let(:user)        { create :user }
    context "and offer is draft" do
      let(:offer)     { create :offer, state: 'draft', created_by: user }
      let(:can)       { [:index, :show, :create, :update, :destroy] }
      let(:cannot)    { [:manage] }
      it{ can.each do |do_action|
        should be_able_to(do_action, offer)
      end}
      it{ cannot.each do |do_action|
        should_not be_able_to(do_action, offer)
      end}
    end

    context "and offer is submitted" do
      let(:offer)     { create :offer, state: 'submitted', created_by: user }
      let(:can)       { [:index, :show, :create, :update, :destroy] }
      let(:cannot)    { [:manage] }
      it{ can.each do |do_action|
        should be_able_to(do_action, offer)
      end}
      it{ cannot.each do |do_action|
        should_not be_able_to(do_action, offer)
      end}
    end

    context "and offer is scheduled" do
      let(:offer)     { create :offer, state: 'scheduled', created_by: user }
      let(:can)       { [:index, :show, :update, :destroy] }
      let(:cannot)    { [:manage] }
      it{ can.each do |do_action|
        should be_able_to(do_action, offer)
      end}
      it{ cannot.each do |do_action|
        should_not be_able_to(do_action, offer)
      end}
    end
  end

  context "when not Owner" do
    let(:user)   { create :user }
    let(:offer)  { create :offer }
    let(:can)    { [:create] }
    let(:cannot) { [:index, :show, :update, :destroy, :manage] }
    it{ can.each do |do_action|
      should be_able_to(do_action, offer)
    end}
    it{ cannot.each do |do_action|
      should_not be_able_to(do_action, offer)
    end}
  end

  context "when Anonymous" do
    let(:user)  { nil }
    let(:offer) { create :offer }
    it{ all_actions.each { |do_action| should_not be_able_to(do_action, offer) } }
  end

end
