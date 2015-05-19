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
    let(:user)     { create(:user, :supervisor) }
    let(:package_type) { create :package_type }
    let(:can)      { [:index, :show] }
    let(:cannot)   { [:create, :update, :destroy, :manage] }
    it{ can.each do |do_action|
      is_expected.to be_able_to(do_action, package_type)
    end}
    it{ cannot.each do |do_action|
      is_expected.to_not be_able_to(do_action, package_type)
    end}
  end

  context "when Reviewer" do
    let(:user)     { create(:user, :reviewer) }
    let(:package_type) { create :package_type }
    let(:can)      { [:index, :show] }
    let(:cannot)   { [:create, :update, :destroy, :manage] }
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
    it{ all_actions.each { |do_action| is_expected.to_not be_able_to(do_action, package_type) } }
  end

end
