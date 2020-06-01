require 'rails_helper'

RSpec.describe CancellationReason, type: :model do

  it { is_expected.to have_db_column(:name_en).of_type(:string) }
  it { is_expected.to have_db_column(:name_zh_tw).of_type(:string) }
  it { is_expected.to have_db_column(:visible_to_offer).of_type(:boolean) }
  it { is_expected.to have_db_column(:visible_to_order).of_type(:boolean) }
  it { is_expected.to validate_presence_of(:name_en) }

  describe "scope: visible_to_offer" do
    let!(:offer_cancellation_reason) { create :cancellation_reason, visible_to_offer: true, visible_to_order: false }
    let!(:order_cancellation_reason) { create :cancellation_reason, visible_to_offer: false, visible_to_order: true }

    it "return records having visible_to_offer as true" do
      visible_scope_ids = described_class.visible_to_offer.pluck(:id)
      expect(visible_scope_ids).to include(offer_cancellation_reason.id)
      expect(visible_scope_ids).to_not include(order_cancellation_reason.id)
    end
  end

  describe "scope: visible_to_order" do
    let!(:offer_cancellation_reason) { create :cancellation_reason, visible_to_offer: true, visible_to_order: false }
    let!(:order_cancellation_reason) { create :cancellation_reason, visible_to_offer: false, visible_to_order: true }

    it "return records having visible_to_order as true" do
      visible_scope_ids = described_class.visible_to_order.pluck(:id)
      expect(visible_scope_ids).to include(order_cancellation_reason.id)
      expect(visible_scope_ids).to_not include(offer_cancellation_reason.id)
    end
  end

  describe "#cancellation_reasons_for" do
    let!(:offer_cancellation_reason) { create :cancellation_reason, visible_to_offer: true, visible_to_order: false }
    let!(:order_cancellation_reason) { create :cancellation_reason, visible_to_offer: false, visible_to_order: true }

    it "returns order reasons if 'order' type is passed" do
      reasons = described_class.cancellation_reasons_for("order")
      expect(reasons.size).to eq(1)
      expect(reasons.pluck(:id)).to_not include(offer_cancellation_reason.id)
      expect(reasons.pluck(:id)).to include(order_cancellation_reason.id)
    end

    it "returns order reasons if 'offer' type is passed" do
      reasons = described_class.cancellation_reasons_for("offer")
      expect(reasons.size).to eq(1)
      expect(reasons.pluck(:id)).to include(offer_cancellation_reason.id)
      expect(reasons.pluck(:id)).to_not include(order_cancellation_reason.id)
    end

    it "returns all records if other type is passed" do
      reasons = described_class.cancellation_reasons_for("all")
      expect(reasons.size).to eq(2)
      expect(reasons.pluck(:id)).to include(offer_cancellation_reason.id)
      expect(reasons.pluck(:id)).to include(order_cancellation_reason.id)
    end
  end
end
