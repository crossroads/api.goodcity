require 'rails_helper'
require 'cancan/matchers'

describe "Package abilities" do

  subject(:ability) { Ability.new(user) }
  let(:all_actions) { [:index, :show, :create, :update, :destroy, :manage] }
  let(:state)       { 'draft' }
  let(:item)        { create :item, state: state }
  let(:package)     { create :package, item: item }

  context "when Administrator" do
    let(:user)    { create(:user, :administrator) }
    it{ all_actions.each { |do_action| is_expected.to be_able_to(do_action, package) } }
  end

  context "when Supervisor" do
    let(:user) { create(:user, :supervisor) }
    context "and package belongs to draft item" do
      let(:can)     { [:index, :show, :create, :update, :destroy] }
      let(:cannot)  { [:manage] }
      it{ can.each do |do_action|
        is_expected.to be_able_to(do_action, package)
      end}
      it{ cannot.each do |do_action|
        is_expected.to_not be_able_to(do_action, package)
      end}
    end
  end

  context "when Reviewer" do
    let(:user)    { create(:user, :reviewer) }
    context "and package belongs to draft item" do
      let(:can)     { [:index, :show, :create, :update, :destroy] }
      let(:cannot)  { [:manage] }
      it{ can.each do |do_action|
        is_expected.to be_able_to(do_action, package)
      end}
      it{ cannot.each do |do_action|
        is_expected.to_not be_able_to(do_action, package)
      end}
    end

    context "and package belongs to submitted item" do
      let(:state)   { 'submitted' }
      let(:can)     { [:index, :show, :create, :update, :destroy] }
      let(:cannot)  { [:manage] }
      it{ can.each do |do_action|
        is_expected.to be_able_to(do_action, package)
      end}
      it{ cannot.each do |do_action|
        is_expected.to_not be_able_to(do_action, package)
      end}
    end
  end

  context "when Owner" do
    let(:user)  { create :user }
    let(:offer) { create :offer, created_by: user }
    let(:item)  { create :item, offer: offer, state: state }

    context "and package belongs to draft item" do
      let(:can)     { [:index, :show, :create, :update, :destroy] }
      let(:cannot)  { [:manage] }
      it{ can.each do |do_action|
        is_expected.to be_able_to(do_action, package)
      end}
      it{ cannot.each do |do_action|
        is_expected.to_not be_able_to(do_action, package)
      end}
    end

    context "and package belongs to submitted item" do
      let(:state)   { 'submitted' }
      let(:can)     { [:index, :show, :create, :update] }
      let(:cannot)  { [:destroy, :manage] }
      it{ can.each do |do_action|
        is_expected.to be_able_to(do_action, package)
      end}
      it{ cannot.each do |do_action|
        is_expected.to_not be_able_to(do_action, package)
      end}
    end
  end

  context "when not Owner" do
    let(:user)    { create :user }
    it{ all_actions.each { |do_action| is_expected.to_not be_able_to(do_action, package) } }
  end

  context "when Anonymous" do
    let(:user)    { nil }
    it{ all_actions.each { |do_action| is_expected.to_not be_able_to(do_action, package) } }
  end

end
