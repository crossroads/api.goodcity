require 'rails_helper'

RSpec.describe CancellationReason, type: :model do

  it { is_expected.to have_db_column(:name_en).of_type(:string) }
  it { is_expected.to have_db_column(:name_zh_tw).of_type(:string) }
  it { is_expected.to have_db_column(:visible_to_offer).of_type(:boolean) }
  it { is_expected.to have_db_column(:visible_to_order).of_type(:boolean) }
  it { is_expected.to validate_presence_of(:name_en) }

  describe "scope: visible_to_offer" do
    let!(:offer_cancellation_reason) { create :cancellation_reason, :visible_to_offer }
    let!(:order_cancellation_reason) { create :cancellation_reason, :visible_to_order }

    it "return records having visible_to_offer as true" do
      visible_scope_ids = CancellationReason.visible_to_offer.pluck(:id)
      expect(visible_scope_ids).to include(offer_cancellation_reason.id)
      expect(visible_scope_ids).to_not include(order_cancellation_reason.id)
    end
  end

  describe "scope: visible_to_order" do
    let!(:offer_cancellation_reason) { create :cancellation_reason, :visible_to_offer }
    let!(:order_cancellation_reason) { create :cancellation_reason, :visible_to_order }

    it "return records having visible_to_order as true" do
      visible_scope_ids = CancellationReason.visible_to_order.pluck(:id)
      expect(visible_scope_ids).to include(order_cancellation_reason.id)
      expect(visible_scope_ids).to_not include(offer_cancellation_reason.id)
    end
  end

end
