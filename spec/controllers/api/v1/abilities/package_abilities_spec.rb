require 'rails_helper'
require 'cancan/matchers'

describe "Package abilities" do

    subject(:ability) { Api::V1::Ability.new(user) }
  let(:all_actions) { [:index, :show, :update, :destroy, :manage] }
  let(:unpermitted_actions) {[:update, :destroy, :manage]}
  let(:limited_actions) {[:index, :show]}
  let(:state)       { 'draft' }
  let(:item)        { create :item, state: state }
  let(:package)     { create :package, item: item }
  let(:published_package)  { create :package, item: item, allow_web_publish: true }

  context "when Supervisor" do
    let(:user) { create(:user, :with_can_manage_packages_permission, role_name: 'Supervisor') }
    context "and package belongs to draft item" do
      let(:can)     { [:index, :show, :create, :update, :destroy] }
      let(:cannot)  { [:manage] }
      it{ can.each do |do_action|
        is_expected.to be_able_to(do_action, package)
      end}
      it{ cannot.each do |do_action|
        is_expected.to_not be_able_to(do_action, package)
      end}
    end
  end

  context "when Reviewer" do
    let(:user)    { create(:user, :with_can_manage_packages_permission, role_name: 'Reviewer') }
    context "and package belongs to draft item" do
      let(:can)     { [:index, :show, :create, :update, :destroy] }
      let(:cannot)  { [:manage] }
      it{ can.each do |do_action|
        is_expected.to be_able_to(do_action, package)
      end}
      it{ cannot.each do |do_action|
        is_expected.to_not be_able_to(do_action, package)
      end}
    end

    context "and package belongs to submitted item" do
      let(:state)   { 'submitted' }
      let(:can)     { [:index, :show, :create, :update, :destroy] }
      let(:cannot)  { [:manage] }
      it{ can.each do |do_action|
        is_expected.to be_able_to(do_action, package)
      end}
      it{ cannot.each do |do_action|
        is_expected.to_not be_able_to(do_action, package)
      end}
    end
  end

  context "when not Owner" do
    let(:user)    { create :user }
    it{ unpermitted_actions.each { |do_action| is_expected.to_not be_able_to(do_action, package) } }
  end

  context "when Anonymous" do
    let(:user)    { nil }
    let(:can) { [:index, :show] }

    it{ unpermitted_actions.each { |do_action| is_expected.to_not be_able_to(do_action, package) } }

    it { limited_actions.each {|do_action| is_expected.to be_able_to(do_action, published_package)}}
  end

  context "when api_write" do
    let(:user) { create :user, :api_write }
    it{  is_expected.to be_able_to(:create, package)  }
  end

end
