require 'rails_helper'
require 'cancan/matchers'

describe "PackageType abilities" do

  subject(:ability) { Api::V1::Ability.new(user) }
  let(:all_actions) { [:index, :show, :create, :update, :destroy, :manage] }
  let(:package_type) { create :package_type }

  context "when can_add_package_types (Order fulfilment)" do
    let(:user)   { create(:user, :with_can_add_package_types_permission, role_name: 'Order fulfilment') }
    let(:can)    { [:index, :show, :create, :update] }
    let(:cannot) { [:destroy, :manage] }
    it { can.each { |a| is_expected.to be_able_to(a, package_type) } }
    it { cannot.each { |a| is_expected.to_not be_able_to(a, package_type) } }
  end

  context "when Reviewer with can_add_package_types" do
    let(:user)   { create(:user, :with_can_add_package_types_permission, role_name: 'Reviewer') }
    let(:can)    { [:index, :show, :create, :update] }
    let(:cannot) { [:destroy, :manage] }
    it { can.each { |a| is_expected.to be_able_to(a, package_type) } }
    it { cannot.each { |a| is_expected.to_not be_able_to(a, package_type) } }
  end

  context "when Supervisor with can_manage_settings" do
    let(:user)   { create(:user, :with_can_manage_settings_permission, role_name: 'Supervisor') }
    let(:can)    { [:index, :show, :create, :update, :destroy] }
    let(:cannot) { [:manage] }
    it { can.each { |a| is_expected.to be_able_to(a, package_type) } }
    it { cannot.each { |a| is_expected.to_not be_able_to(a, package_type) } }
  end

  context "when Anonymous" do
    let(:user) { nil }
    let(:can)  { [:index, :show] }
    it { can.each { |a| is_expected.to be_able_to(a, package_type) } }
    it { (all_actions - can).each { |a| is_expected.to_not be_able_to(a, package_type) } }
  end
end
