require 'rails_helper'
require 'cancan/matchers'

describe "PackageType abilities" do

  subject(:ability) { Ability.new(user) }
  let(:all_actions) { [:index, :show, :create, :update, :destroy, :manage] }

  context "when Administrator" do
    let(:user)     { create(:user, :administrator) }
    let(:package_type) { create :package_type }
    it{ all_actions.each { |do_action| is_expected.to be_able_to(do_action, package_type) } }
  end

  context "when Supervisor" do
    let(:user)     { create(:user, :with_can_add_package_types_permission, role_name: 'Supervisor') }
    let(:package_type) { create :package_type }
    let(:can)      { [:index, :show, :create] }
    let(:cannot)   { [:update, :destroy, :manage] }
    it{ can.each do |do_action|
      is_expected.to be_able_to(do_action, package_type)
    end}
    it{ cannot.each do |do_action|
      is_expected.to_not be_able_to(do_action, package_type)
    end}
  end

  context "when Reviewer" do
    let(:user)     { create(:user, :with_can_add_package_types_permission, role_name: 'Reviewer') }
    let(:package_type) { create :package_type }
    let(:can)      { [:index, :show, :create] }
    let(:cannot)   { [:update, :destroy, :manage] }
    it{ can.each do |do_action|
      is_expected.to be_able_to(do_action, package_type)
    end}
    it{ cannot.each do |do_action|
      is_expected.to_not be_able_to(do_action, package_type)
    end}
  end

  context "when Anonymous" do
    let(:user)     { nil }
    let(:package_type) { create :package_type }
    let(:can) { [:index, :show] }
    it{ can.each { |do_action| is_expected.to be_able_to(do_action, package_type) } }
    it{ (all_actions - can).each { |do_action| is_expected.to_not be_able_to(do_action, package_type) } }
  end

end
