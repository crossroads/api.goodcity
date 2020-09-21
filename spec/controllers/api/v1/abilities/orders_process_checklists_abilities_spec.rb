require "rails_helper"
require "cancan/matchers"

describe "OrdersProcessChecklist abilities" do
    subject(:ability) { Api::V1::Ability.new(user) }

  context "when Supervisor" do
    let(:user) { create(:user, :supervisor, :with_can_access_orders_process_checklists_permission) }
    let(:orders_process_checklist) { create :orders_process_checklist }

    it { is_expected.to be_able_to(:index, orders_process_checklist) }
  end

  context "when Reviewer" do
    let(:user) { create(:user, :order_fulfilment, :with_can_access_orders_process_checklists_permission) }
    let(:orders_process_checklist) { create :orders_process_checklist }

    it { is_expected.to be_able_to(:index, orders_process_checklist) }
  end

  context "when Anonymous" do
    let(:user) { nil }
    let(:orders_process_checklist) { create :orders_process_checklist }

    it { is_expected.to_not be_able_to(:index, orders_process_checklist) }
  end
end
