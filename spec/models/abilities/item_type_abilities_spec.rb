require 'rails_helper'
require 'cancan/matchers'

describe "ItemType abilities" do

  subject(:ability) { Ability.new(user) }
  let(:all_actions) { [:index, :show, :create, :update, :destroy, :manage] }

  context "when Administrator" do
    let(:user)     { create :administrator }
    let(:item_type) { create :item_type }
    it{ all_actions.each { |do_action| should be_able_to(do_action, item_type) } }
  end

  context "when Supervisor" do
    let(:user)     { create :supervisor }
    let(:item_type) { create :item_type }
    let(:can)      { [:index, :show] }
    let(:cannot)   { [:create, :update, :destroy, :manage] }
    it{ can.each do |do_action|
      should be_able_to(do_action, item_type)
    end}
    it{ cannot.each do |do_action|
      should_not be_able_to(do_action, item_type)
    end}
  end

  context "when Reviewer" do
    let(:user)     { create :reviewer }
    let(:item_type) { create :item_type }
    let(:can)      { [:index, :show] }
    let(:cannot)   { [:create, :update, :destroy, :manage] }
    it{ can.each do |do_action|
      should be_able_to(do_action, item_type)
    end}
    it{ cannot.each do |do_action|
      should_not be_able_to(do_action, item_type)
    end}
  end

  context "when Anonymous" do
    let(:user)     { nil }
    let(:item_type) { create :item_type }
    it{ all_actions.each { |do_action| should_not be_able_to(do_action, item_type) } }
  end

end
