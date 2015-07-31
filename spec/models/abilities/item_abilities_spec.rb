require 'rails_helper'
require 'cancan/matchers'

describe "Item abilities" do

  subject(:ability) { Ability.new(user) }
  let(:all_actions) { [:index, :show, :create, :update, :destroy, :manage] }
  let(:state)       { 'draft' }
  let(:item)        { create :item, state: state }

  context "when Administrator" do
    let(:user) { create(:user, :administrator) }
    it{ all_actions.each { |do_action| is_expected.to be_able_to(do_action, item) } }
  end

  context "when Supervisor" do
    let(:user)  { create(:user, :supervisor) }
    context "and item is draft" do
      let(:can)    { [:index, :show, :create, :update, :destroy] }
      let(:cannot) { [:manage] }
      it{ can.each do |do_action|
        is_expected.to be_able_to(do_action, item)
      end}
      it{ cannot.each do |do_action|
        is_expected.to_not be_able_to(do_action, item)
      end}
    end
  end

  context "when Reviewer" do
    let(:user) { create(:user, :reviewer) }

    context "and item is draft" do
      let(:can)    { [:index, :show, :create, :update, :destroy] }
      let(:cannot) { [:manage] }
      it{ can.each do |do_action|
        is_expected.to be_able_to(do_action, item)
      end}
      it{ cannot.each do |do_action|
        is_expected.to_not be_able_to(do_action, item)
      end}
    end

    context "and item is submitted" do
      let(:state)  { 'submitted' }
      let(:can)    { [:index, :show, :create, :update, :destroy] }
      let(:cannot) { [:manage] }
      it{ can.each do |do_action|
        is_expected.to be_able_to(do_action, item)
      end}
      it{ cannot.each do |do_action|
        is_expected.to_not be_able_to(do_action, item)
      end}
    end
  end

  context "when Owner" do
    let(:user)     { create :user }
    let(:offer)    { create :offer, created_by: user }
    context "and item is draft" do
      let(:item)   { create :item, state: 'draft', offer: offer }
      let(:can)    { [:index, :show, :create, :update, :destroy] }
      let(:cannot) { [:manage] }
      it{ can.each do |do_action|
        is_expected.to be_able_to(do_action, item)
      end}
      it{ cannot.each do |do_action|
        is_expected.to_not be_able_to(do_action, item)
      end}
    end

    context "and item is submitted" do
      let(:item)   { create :item, state: 'submitted', offer: offer }
      let(:can)    { [:index, :show, :create, :update, :destroy] }
      let(:cannot) { [:manage] }
      it{ can.each do |do_action|
        is_expected.to be_able_to(do_action, item)
      end}
      it{ cannot.each do |do_action|
        is_expected.to_not be_able_to(do_action, item)
      end}
    end

    context "and item has received package" do
      let!(:item)   { create :item, state: 'accepted', offer: offer }
      let!(:package) { create :package, state: "received", item: item }
      let(:cannot) { [:update] }
      it{ cannot.each do |do_action|
        is_expected.to_not be_able_to(do_action, item)
      end}
    end
  end

  context "when not Owner" do
    let(:user)   { create :user }
    it{ all_actions.each { |do_action| is_expected.to_not be_able_to(do_action, item) } }
  end

  context "when Anonymous" do
    let(:user)  { nil }
    it{ all_actions.each { |do_action| is_expected.to_not be_able_to(do_action, item) } }
  end

end
