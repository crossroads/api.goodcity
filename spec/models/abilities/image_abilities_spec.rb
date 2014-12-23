require 'rails_helper'
require 'cancan/matchers'

describe "Image abilities" do

  subject(:ability) { Ability.new(user) }
  let(:all_actions) { [:index, :show, :create, :update, :destroy, :manage] }
  let(:state)       { 'draft' }
  let(:item)        { create :item, state: state }
  let(:image)       { create :image, item: item }

  context "when Administrator" do
    let(:user)    { create(:user, :administrator) }
    it{ all_actions.each { |do_action| should be_able_to(do_action, image) } }
  end

  context "when Supervisor" do
    let(:user) { create(:user, :supervisor) }
    context "and image belongs to draft item" do
      let(:can)     { [:index, :show, :create, :update, :destroy] }
      let(:cannot)  { [:manage] }
      it{ can.each do |do_action|
        should be_able_to(do_action, image)
      end}
      it{ cannot.each do |do_action|
        should_not be_able_to(do_action, image)
      end}
    end
  end

  context "when Reviewer" do
    let(:user)    { create(:user, :reviewer) }
    context "and image belongs to draft item" do
      let(:can)     { [:index, :show, :create, :update, :destroy] }
      let(:cannot)  { [:manage] }
      it{ can.each do |do_action|
        should be_able_to(do_action, image)
      end}
      it{ cannot.each do |do_action|
        should_not be_able_to(do_action, image)
      end}
    end

    context "and image belongs to submitted item" do
      let(:state)   { 'submitted' }
      let(:can)     { [:index, :show, :create, :update, :destroy] }
      let(:cannot)  { [:manage] }
      it{ can.each do |do_action|
        should be_able_to(do_action, image)
      end}
      it{ cannot.each do |do_action|
        should_not be_able_to(do_action, image)
      end}
    end
  end

  context "when Owner" do
    let(:user)  { create :user }
    let(:offer) { create :offer, created_by: user }
    let(:item)  { create :item, offer: offer, state: state }

    context "and image belongs to draft item" do
      let(:can)     { [:index, :show, :create, :update, :destroy] }
      let(:cannot)  { [:manage] }
      it{ can.each do |do_action|
        should be_able_to(do_action, image)
      end}
      it{ cannot.each do |do_action|
        should_not be_able_to(do_action, image)
      end}
    end

    context "and image belongs to submitted item" do
      let(:state)   { 'submitted' }
      let(:can)     { [:index, :show, :create, :update, :destroy] }
      let(:cannot)  { [:manage] }
      it{ can.each do |do_action|
        should be_able_to(do_action, image)
      end}
      it{ cannot.each do |do_action|
        should_not be_able_to(do_action, image)
      end}
    end
  end

  context "when not Owner" do
    let(:user)    { create :user }
    it{ all_actions.each { |do_action| should_not be_able_to(do_action, image) } }
  end

  context "when Anonymous" do
    let(:user)    { nil }
    it{ all_actions.each { |do_action| should_not be_able_to(do_action, image) } }
  end

end
