require 'rails_helper'
require 'cancan/matchers'

describe "RejectionReason abilities" do

  subject(:ability) { Ability.new(user) }
  let(:all_actions) { [:index, :show, :create, :update, :destroy, :manage] }

  context "when Administrator" do
    let(:user)     { create(:user, :administrator) }
    let(:rejection_reason) { create :rejection_reason }
    it{ all_actions.each { |do_action| is_expected.to be_able_to(do_action, rejection_reason) } }
  end

  context "when Supervisor" do
    let(:user)     { create(:user, :supervisor) }
    let(:rejection_reason) { create :rejection_reason }
    let(:can)      { [:index, :show] }
    let(:cannot)   { [:create, :update, :destroy, :manage] }
    it{ can.each do |do_action|
      is_expected.to be_able_to(do_action, rejection_reason)
    end}
    it{ cannot.each do |do_action|
      is_expected.to_not be_able_to(do_action, rejection_reason)
    end}
  end

  context "when Reviewer" do
    let(:user)     { create(:user, :reviewer) }
    let(:rejection_reason) { create :rejection_reason }
    let(:can)      { [:index, :show] }
    let(:cannot)   { [:create, :update, :destroy, :manage] }
    it{ can.each do |do_action|
      is_expected.to be_able_to(do_action, rejection_reason)
    end}
    it{ cannot.each do |do_action|
      is_expected.to_not be_able_to(do_action, rejection_reason)
    end}
  end

  context "when Anonymous" do
    let(:user)     { nil }
    let(:rejection_reason) { create :rejection_reason }
    it{ all_actions.each { |do_action| is_expected.to_not be_able_to(do_action, rejection_reason) } }
  end

end
