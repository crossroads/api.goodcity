require 'rails_helper'
require 'cancan/matchers'

describe "Delivery abilities" do

  subject(:ability) { Ability.new(user) }
  let(:all_actions) { [:index, :show, :create, :update, :destroy, :manage, :confirm_delivery] }

  context "when Administrator" do
    let(:user)     { create(:user, :administrator) }
    let(:delivery) { create :delivery }
    it{ all_actions.each { |do_action| is_expected.to be_able_to(do_action, delivery) } }
  end

  context "when Supervisor" do
    let(:user)     { create(:user, :supervisor) }
    let(:delivery) { create :delivery }
    let(:can)      { [:index, :show, :create, :update, :destroy, :confirm_delivery] }
    let(:cannot)   { [:manage] }
    it { can.each { |do_action| is_expected.to be_able_to(do_action, delivery) } }
    it { cannot.each { |do_action| is_expected.to_not be_able_to(do_action, delivery) } }
  end

  context "when Reviewer" do
    let(:user)     { create(:user, :reviewer) }
    let(:delivery) { create :delivery }
    let(:can)      { [:index, :show, :create, :update, :destroy, :confirm_delivery] }
    let(:cannot)   { [:manage] }
    it { can.each { |do_action| is_expected.to be_able_to(do_action, delivery) } }
    it { cannot.each { |do_action| is_expected.to_not be_able_to(do_action, delivery) } }
  end

  context "when Owner" do
    let(:user)     { delivery.offer.created_by }
    let(:delivery) { create :delivery }
    let(:can)      { [:show, :create, :update, :destroy, :confirm_delivery] }
    let(:cannot)   { [:index, :manage] }
    it { can.each { |do_action| is_expected.to be_able_to(do_action, delivery) } }
    it { cannot.each { |do_action| is_expected.to_not be_able_to(do_action, delivery) } }
  end

  context "when not Owner" do
    let(:user)     { create(:user) }
    let(:delivery) { create :delivery }
    let(:can)      { [:create] }
    let(:cannot)   { [:show, :index, :update, :destroy, :confirm_delivery, :manage] }
    it { can.each { |do_action| is_expected.to be_able_to(do_action, delivery) } }
    it { cannot.each { |do_action| is_expected.to_not be_able_to(do_action, delivery) } }
  end

  context "when Anonymous" do
    let(:user)     { nil }
    let(:delivery) { create :delivery }
    let(:can)      { [] }
    let(:cannot)   { [:index, :show, :create, :update, :destroy, :manage, :confirm_delivery] }
    it { can.each { |do_action| is_expected.to be_able_to(do_action, delivery) } }
    it { cannot.each { |do_action| is_expected.to_not be_able_to(do_action, delivery) } }
  end

end
