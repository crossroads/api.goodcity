require 'rails_helper'
require 'cancan/matchers'

describe "OrdersPackage abilities" do
  subject(:ability) { Ability.new(user) }
  let(:all_actions) { [:index, :search, :show, :destroy, :exec_action] }
  let(:orders_package) { create :orders_package }

  context "when Administrator" do
    let(:user) { create(:user, :administrator) }
    it{ all_actions.each { |do_action| is_expected.to be_able_to(do_action, orders_package) } }
  end

  context "when Supervisor" do
    let(:user)  { create(:user, :with_can_manage_orders_packages_permission, role_name: 'Supervisor') }
    it{ all_actions.each { |do_action| is_expected.to be_able_to(do_action, orders_package) } }
  end

  context "when Reviewer" do
    let(:user) { create(:user, :with_can_manage_orders_packages_permission, role_name: 'Reviewer') }
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

  context "when Charity user" do
    let(:user) { create :user, :charity}
    context "created the order with orders_packages" do
      let(:order) { create :order, :with_orders_packages, created_by_id: user.id }
      let(:orders_package) { order.orders_packages.first }
      it{ all_actions.each { |do_action| is_expected.to be_able_to(do_action, orders_package) } }
    end
    context "submitted the order with orders_packages" do
      let(:order) { create :order, :with_orders_packages, submitted_by_id: user.id }
      let(:orders_package) { order.orders_packages.first }
      it{ all_actions.each { |do_action| is_expected.to be_able_to(do_action, orders_package) } }
    end
    context "didn't create or submit the order with orders_packages" do
      let(:order) { create :order, :with_orders_packages, created_by_id: nil, submitted_by_id: nil }
      let(:orders_package) { order.orders_packages.first }
      it{ all_actions.each { |do_action| is_expected.to_not be_able_to(do_action, orders_package) } }
    end
  end
end
