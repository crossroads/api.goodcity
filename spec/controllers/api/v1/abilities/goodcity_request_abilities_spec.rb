require 'rails_helper'
require 'cancan/matchers'

describe "GoodcityRequest abilities" do

  before { allow_any_instance_of(PushService).to receive(:notify) }
  
    subject(:ability) { Api::V1::Ability.new(user) }
  let(:all_actions) { [:index, :show, :create, :update, :destroy, :manage, :search] }

  context "as a Supervisor" do
    let(:user) { create(:user, :with_can_manage_goodcity_requests_permission, role_name: 'Supervisor') }
    let(:goodcity_request) { create :goodcity_request }
    let(:can) { [:index, :show, :create, :update, :destroy] }

    it { can.each do |do_action|
      is_expected.to be_able_to(do_action, goodcity_request)
    end }
  end

  context "as a Charity user" do
    let(:user) { create(:user, :charity) }
    let(:organisation) { user.active_organisations.first }
    let(:other_organisation) { create :organisation }
    let(:goodcity_request) { create :goodcity_request, order: order }

    context "when the goodcity_request's order belongs to my order" do
      let(:order) { create(:order, created_by: user) }
      let(:can) { [:index, :show, :create, :update, :destroy] }

      it { can.each do |do_action|
        is_expected.to be_able_to(do_action, goodcity_request)
      end }
    end

    context "when the goodcity_request's order doesn't belongs to me" do
      let(:order) { create(:order) }
      let(:cannot) { [:index, :show, :create, :update, :destroy] }

      it { cannot.each do |do_action|
        is_expected.not_to be_able_to(do_action, goodcity_request)
      end }
    end
  end
end
