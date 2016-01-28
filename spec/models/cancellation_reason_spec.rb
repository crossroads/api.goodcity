require 'rails_helper'

RSpec.describe CancellationReason, type: :model do

  it { is_expected.to have_db_column(:name_en).of_type(:string) }
  it { is_expected.to have_db_column(:name_zh_tw).of_type(:string) }
  it { is_expected.to have_db_column(:visible_to_admin).of_type(:boolean) }
  it { is_expected.to validate_presence_of(:name_en) }

  describe "scope: visible" do
    it "return records having visible_to_admin as true" do
      visible_reason = create :cancellation_reason, visible_to_admin: true
      invisible_reason = create :cancellation_reason, visible_to_admin: false
      visible_scope = CancellationReason.visible
      expect(visible_scope).to include(visible_reason)
      expect(visible_scope).to_not include(invisible_reason)
    end
  end

end
