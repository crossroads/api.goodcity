require 'rails_helper'

RSpec.describe CancellationReason, type: :model do

  it { is_expected.to have_db_column(:name_en).of_type(:string) }
  it { is_expected.to have_db_column(:name_zh_tw).of_type(:string) }
  it { is_expected.to have_db_column(:visible_to_offer).of_type(:boolean) }
  it { is_expected.to have_db_column(:visible_to_order).of_type(:boolean) }
  it { is_expected.to validate_presence_of(:name_en) }

  describe "scope: visible_to_offer" do
    let!(:visible_reason) { create :cancellation_reason, :visible }
    let!(:invisible_reason) { create :cancellation_reason, :invisible }
    it "return records having visible_to_admin as true" do
      visible_scope_ids = CancellationReason.visible_to_offer.pluck(:id)
      expect(visible_scope_ids).to include(visible_reason.id)
      expect(visible_scope_ids).to_not include(invisible_reason.id)
    end
  end

end
