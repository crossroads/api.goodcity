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

  describe "Validations" do
    it "should have atleast one package_categories" do
      package_type = build(:package_type)
      package_category = create(:package_category)
      package_type.package_categories << package_category
      expect(package_type.save).to be(true)
    end

    it "fails if there is no package_categories" do
      package_type = build(:package_type)
      package_type.package_categories.destroy_all
      expect(package_type.save).to be(false)
      expect(package_type.errors.messages).to include({:package_categories=>["can't be blank"]})
    end
  end

  describe 'scope' do
    describe "visible" do
      it "returns records with visible_in_selects true value" do
        expect(PackageType.visible.to_sql).to include("WHERE \"package_types\".\"visible_in_selects\" = 't'")
      end
    end
  end
end
