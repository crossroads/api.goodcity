require 'rails_helper'
require 'cancan/matchers'

describe "User abilities" do

  subject(:ability) { Api::V1::Ability.new(user) }
  let(:all_actions) { %i[index show create update destroy manage current_user_profile can_read_or_modify_user] }

  context "when Supervisor" do
    let(:user) { create(:user, :with_supervisor_role, :with_can_mention_users_permission, :with_can_read_or_modify_user_permission) }
    let(:person) { create :user }
    let(:can)    { %i[create index show update current_user_profile mentionable_users] }
    let(:cannot) { %i[destroy manage] }
    it{ can.each do |do_action|
      is_expected.to be_able_to(do_action, person)
    end}
    it{ cannot.each do |do_action|
      is_expected.to_not be_able_to(do_action, person)
    end}
  end

  context "when Reviewer" do
    let(:user) { create(:user, :with_reviewer_role, :with_can_mention_users_permission, :with_can_read_or_modify_user_permission) }
    let(:person) { create :user }
    let(:can)    { %i[create index show update current_user_profile mentionable_users] }
    let(:cannot) { %i[destroy manage] }
    it{ can.each do |do_action|
      is_expected.to be_able_to(do_action, person)
    end}
    it{ cannot.each do |do_action|
      is_expected.to_not be_able_to(do_action, person)
    end}
  end

  context "when Stock-Administrator" do
    let(:user) { create(:user, :with_stock_administrator_role, :with_can_read_users_permission) }
    let(:person) { create :user }
    let(:can)    { %i[index show] }
    let(:cannot) { %i[create destroy manage] }
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
    let(:can)    { %i[show update current_user_profile] }
    let(:cannot) { %i[index create destroy manage mentionable_users] }
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
    let(:cannot) { %i[show update index create destroy manage mentionable_users] }
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
