require 'rails_helper'
require 'cancan/matchers'

describe "contact abilities" do

  subject(:ability) { Ability.new(user) }
  let(:all_actions) { [:create, :destroy, :manage] }

  context "when Administrator" do
    let(:user)     { create(:user, :administrator) }
    let(:contact) { create :contact }
    it{ all_actions.each { |do_action| is_expected.to be_able_to(do_action, contact) } }
  end

  context "when Supervisor" do
    let(:user)     { create(:user, :supervisor) }
    let(:contact)  { create :contact }
    let(:can)      { [:create, :destroy] }
    let(:cannot)   { [:manage] }
    it { can.each { |do_action| is_expected.to be_able_to(do_action, contact) } }
    it { cannot.each { |do_action| is_expected.to_not be_able_to(do_action, contact) } }
  end

  context "when Reviewer" do
    let(:user)     { create(:user, :reviewer) }
    let(:contact)  { create :contact }
    let(:can)      { [:create, :destroy] }
    let(:cannot)   { [:manage] }
    it { can.each { |do_action| is_expected.to be_able_to(do_action, contact) } }
    it { cannot.each { |do_action| is_expected.to_not be_able_to(do_action, contact) } }
  end

  context "when Owner" do
    let(:delivery) { create :gogovan_delivery }
    let(:user)     { delivery.offer.created_by }
    let(:contact)  { delivery.contact }
    let(:can)      { [:create, :destroy] }
    let(:cannot)   { [:manage] }
    it { can.each { |do_action| is_expected.to be_able_to(do_action, contact) } }
    it { cannot.each { |do_action| is_expected.to_not be_able_to(do_action, contact) } }
  end

  context "when not Owner" do
    let(:user)     { create(:user) }
    let(:contact)  { create :contact }
    let(:can)      { [:create] }
    let(:cannot)   { [:destroy] }
    it { can.each { |do_action| is_expected.to be_able_to(do_action, contact) } }
    it { cannot.each { |do_action| is_expected.to_not be_able_to(do_action, contact) } }
  end

  context "when Anonymous" do
    let(:user)     { nil }
    let(:contact)  { create :contact }
    let(:can)      { [] }
    let(:cannot)   { [:create, :destroy, :manage] }
    it { can.each { |do_action| is_expected.to be_able_to(do_action, contact) } }
    it { cannot.each { |do_action| is_expected.to_not be_able_to(do_action, contact) } }
  end

end
