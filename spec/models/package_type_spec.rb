require 'rails_helper'

RSpec.describe PackageType, type: :model do
  describe "Database columns" do
    it { is_expected.to have_db_column(:code).of_type(:string) }
    it { is_expected.to have_db_column(:name_en).of_type(:string) }
    it { is_expected.to have_db_column(:name_zh_tw).of_type(:string) }
    it { is_expected.to have_db_column(:other_terms_en).of_type(:string) }
    it { is_expected.to have_db_column(:other_terms_zh_tw).of_type(:string) }
  end

  describe 'Associations' do
    it { is_expected.to have_many :subpackage_types }
    it { is_expected.to have_many :child_package_types }
  end

  describe 'scope' do
    describe "visible" do
      it "returns records with visible_in_selects true value" do
        expect(PackageType.visible.to_sql).to include("WHERE \"package_types\".\"visible_in_selects\" = 't'")
      end
    end
  end

  describe 'callbacks' do
    let(:package_type) { create :package_type, :with_stockit_id }

    it 'creates default subpackage_type' do
      expect(package_type.subpackage_types.count).to eq 1
      expect(package_type.visible_in_selects).to be_truthy
    end
  end
end
