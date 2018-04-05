require 'rails_helper'
require 'cancan/matchers'

describe "User abilities" do

  subject(:ability) { Ability.new(user) }
  let(:all_actions) { [:index, :show, :create, :update, :destroy, :manage, :current_user_profile] }

  context "when Administrator" do
    let(:user)   { create(:user, :administrator) }
    let(:person) { create :user }
    it{ all_actions.each { |do_action| is_expected.to be_able_to(do_action, person) } }
  end

  context "when Supervisor" do
    let(:user)   { create(:user, :with_can_read_or_modify_user_permission, role_name: 'Supervisor') }
    let(:person) { create :user }
    let(:can)    { [:index, :show, :update, :current_user_profile] }
    let(:cannot) { [:create, :destroy, :manage] }
    it{ can.each do |do_action|
      is_expected.to be_able_to(do_action, person)
    end}
    it{ cannot.each do |do_action|
      is_expected.to_not be_able_to(do_action, person)
    end}
  end

  context "when Reviewer" do
    let(:user)   { create(:user, :with_can_read_or_modify_user_permission, role_name: 'Reviewer') }
    let(:person) { create :user }
    let(:can)    { [:index, :show, :update, :current_user_profile] }
    let(:cannot) { [:create, :destroy, :manage] }
    it{ can.each do |do_action|
      is_expected.to be_able_to(do_action, person)
    end}
    it{ cannot.each do |do_action|
      is_expected.to_not be_able_to(do_action, person)
    end}
  end

  context "when Owner" do
    let(:user)   { create :user }
    let(:person) { user }
    let(:can)    { [:show, :update, :current_user_profile] }
    let(:cannot) { [:index, :create, :destroy, :manage] }
    it{ can.each do |do_action|
      is_expected.to be_able_to(do_action, person)
    end}
    it{ cannot.each do |do_action|
      is_expected.to_not be_able_to(do_action, person)
    end}
  end

  context "when not Owner" do
    let(:user)   { create :user }
    let(:person) { create :user }
    let(:can)    { [:current_user_profile] }
    let(:cannot) { [:show, :update, :index, :create, :destroy, :manage] }
    it{ can.each do |do_action|
      is_expected.to be_able_to(do_action, person)
    end}
    it{ cannot.each do |do_action|
      is_expected.to_not be_able_to(do_action, person)
    end}
  end

  context "when Anonymous" do
    let(:user)   { nil }
    let(:person) { create :user }
    it{ all_actions.each { |do_action| is_expected.to_not be_able_to(do_action, person) } }
  end

end
