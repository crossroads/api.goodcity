require 'rails_helper'
require 'cancan/matchers'

describe "Territory abilities" do

  subject(:ability) { Ability.new(user) }
  let(:all_actions) { [:index, :show, :create, :update, :destroy, :manage] }

  context "when Administrator" do
    let(:user)      { create(:user, :administrator) }
    let(:territory) { create :territory }
    it{ all_actions.each { |do_action| should be_able_to(do_action, territory) } }
  end

  context "when Supervisor" do
    let(:user)      { create(:user, :supervisor) }
    let(:territory) { create :territory }
    let(:can)       { [:index, :show] }
    let(:cannot)    { [:create, :update, :destroy, :manage] }
    it{ can.each do |do_action|
      should be_able_to(do_action, territory)
    end}
    it{ cannot.each do |do_action|
      should_not be_able_to(do_action, territory)
    end}
  end

  context "when Reviewer" do
    let(:user)      { create(:user, :reviewer) }
    let(:territory) { create :territory }
    let(:can)       { [:index, :show] }
    let(:cannot)    { [:create, :update, :destroy, :manage] }
    it{ can.each do |do_action|
      should be_able_to(do_action, territory)
    end}
    it{ cannot.each do |do_action|
      should_not be_able_to(do_action, territory)
    end}
  end

  context "when Anonymous" do
    let(:user)      { nil }
    let(:territory) { create :territory }
    let(:can)       { [:index, :show] }
    let(:cannot)    { [:create, :update, :destroy, :manage] }
    it{ can.each do |do_action|
      should be_able_to(do_action, territory)
    end}
    it{ cannot.each do |do_action|
      should_not be_able_to(do_action, territory)
    end}
  end

end
