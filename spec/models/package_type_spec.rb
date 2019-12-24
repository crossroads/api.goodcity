require 'rails_helper'

RSpec.describe PackageType, type: :model do
  describe "Database columns" do
    it { is_expected.to have_db_column(:code).of_type(:string) }
    it { is_expected.to have_db_column(:name_en).of_type(:string) }
    it { is_expected.to have_db_column(:allow_requests).of_type(:boolean) }
    it { is_expected.to have_db_column(:name_zh_tw).of_type(:string) }
    it { is_expected.to have_db_column(:other_terms_en).of_type(:string) }
    it { is_expected.to have_db_column(:other_terms_zh_tw).of_type(:string) }
    it { is_expected.to have_db_column(:allow_pieces).of_type(:boolean) }
    it { is_expected.to have_db_column(:allow_stock).of_type(:boolean) }
    it { is_expected.to have_db_column(:allow_box).of_type(:boolean) }
    it { is_expected.to have_db_column(:allow_pallet).of_type(:boolean) }
  end

  describe 'Associations' do
    it { is_expected.to have_many :subpackage_types }
    it { is_expected.to have_many :child_package_types }
    it { is_expected.to have_many :goodcity_requests }
  end

  describe 'scope' do
    describe "visible" do
      it "returns records with allow_stock true value" do
        expect(PackageType.visible.to_sql).to include("WHERE \"package_types\".\"allow_stock\" = 't'")
      end
    end
  end
end
