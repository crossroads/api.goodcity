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
end
