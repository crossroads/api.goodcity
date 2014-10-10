require 'rails_helper'
require 'cancan/matchers'

describe "User abilities" do

  subject(:ability) { Ability.new(user) }
  let(:all_actions) { [:index, :show, :create, :update, :destroy, :manage] }

  context "when Administrator" do
    let(:user)   { create(:user, :administrator) }
    let(:person) { create :user }
    it{ all_actions.each { |do_action| should be_able_to(do_action, person) } }
  end

  context "when Supervisor" do
    let(:user)   { create(:user, :supervisor) }
    let(:person) { create :user }
    let(:can)    { [:index, :show, :update] }
    let(:cannot) { [:create, :destroy, :manage] }
    it{ can.each do |do_action|
      should be_able_to(do_action, person)
    end}
    it{ cannot.each do |do_action|
      should_not be_able_to(do_action, person)
    end}
  end

  context "when Reviewer" do
    let(:user)   { create(:user, :reviewer) }
    let(:person) { create :user }
    let(:can)    { [:index, :show, :update] }
    let(:cannot) { [:create, :destroy, :manage] }
    it{ can.each do |do_action|
      should be_able_to(do_action, person)
    end}
    it{ cannot.each do |do_action|
      should_not be_able_to(do_action, person)
    end}
  end

  context "when Owner" do
    let(:user)   { create :user }
    let(:person) { user }
    let(:can)    { [:show, :update] }
    let(:cannot) { [:index, :create, :destroy, :manage] }
    it{ can.each do |do_action|
      should be_able_to(do_action, person)
    end}
    it{ cannot.each do |do_action|
      should_not be_able_to(do_action, person)
    end}
  end

  context "when not Owner" do
    let(:user)   { create :user }
    let(:person) { create :user }
    it{ all_actions.each { |do_action| should_not be_able_to(do_action, person) } }
  end

  context "when Anonymous" do
    let(:user)   { nil }
    let(:person) { create :user }
    it{ all_actions.each { |do_action| should_not be_able_to(do_action, person) } }
  end

end
