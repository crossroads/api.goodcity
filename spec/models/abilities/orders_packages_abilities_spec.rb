require 'rails_helper'
require 'cancan/matchers'

describe "OrdersPackage abilities" do
  subject(:ability) { Ability.new(user) }
  let(:all_actions) { [:index, :search, :show] }
  let(:orders_package) { create :orders_package }

  context "when Administrator" do
    let(:user) { create(:user, :administrator) }
    it{ all_actions.each { |do_action| is_expected.to be_able_to(do_action, orders_package) } }
  end

  context "when Supervisor" do
    let(:user)  { create(:user, :supervisor) }
    it{ all_actions.each { |do_action| is_expected.to be_able_to(do_action, orders_package) } }
  end

  context "when Reviewer" do
    let(:user) { create(:user, :reviewer) }
    it{ all_actions.each { |do_action| is_expected.to be_able_to(do_action, orders_package) } }
  end

  context "when api user" do
    let(:user) { create(:user, :api_user) }
    it{ all_actions.each { |do_action| is_expected.to be_able_to(do_action, orders_package) } }
  end

  context "when normal user" do
    let(:user) { create :user }
    it{ all_actions.each { |do_action| is_expected.to_not be_able_to(do_action, orders_package) } }
  end
end
