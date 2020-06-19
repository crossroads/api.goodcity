require 'rails_helper'
require 'cancan/matchers'

describe "User abilities" do

  subject(:ability) { Ability.new(user) }
  let(:all_actions) { %i[index show create update destroy manage current_user_profile can_read_or_modify_user] }

  context "when Supervisor" do
    let(:user) { create(:user, :with_multiple_roles_and_permissions, roles_and_permissions: {'Supervisor' => ['can_mention_users', 'can_read_or_modify_user']}) }
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
    let(:user) { create(:user, :with_multiple_roles_and_permissions, roles_and_permissions: {'Reviewer' => ['can_mention_users', 'can_read_or_modify_user']}) }
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
