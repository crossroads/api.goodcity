require 'rails_helper'
require 'cancan/matchers'

describe "District abilities" do

    subject(:ability) { Api::V1::Ability.new(user) }
  let(:all_actions) { [:index, :show, :create, :update, :destroy, :manage] }

  context "when Supervisor" do
    let(:user)     { create(:user, :supervisor) }
    let(:district) { create :district }
    let(:can)      { [:index, :show] }
    let(:cannot)   { [:create, :update, :destroy, :manage] }
    it{ can.each do |do_action|
      is_expected.to be_able_to(do_action, district)
    end}
    it{ cannot.each do |do_action|
      is_expected.to_not be_able_to(do_action, district)
    end}
  end

  context "when Reviewer" do
    let(:user)     { create(:user, :reviewer) }
    let(:district) { create :district }
    let(:can)      { [:index, :show] }
    let(:cannot)   { [:create, :update, :destroy, :manage] }
    it{ can.each do |do_action|
      is_expected.to be_able_to(do_action, district)
    end}
    it{ cannot.each do |do_action|
      is_expected.to_not be_able_to(do_action, district)
    end}
  end

  context "when Anonymous" do
    let(:user)     { nil }
    let(:district) { create :district }
    let(:can)      { [:index, :show] }
    let(:cannot)   { [:create, :update, :destroy, :manage] }
    it{ can.each do |do_action|
      is_expected.to be_able_to(do_action, district)
    end}
    it{ cannot.each do |do_action|
      is_expected.to_not be_able_to(do_action, district)
    end}
  end

end
