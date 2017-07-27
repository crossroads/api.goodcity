require 'rails_helper'

RSpec.describe PackageCategoriesPackageType, type: :model do
  describe 'Association' do
    it { is_expected.to belong_to :package_category }
    it { is_expected.to belong_to :package_type }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:package_type_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:package_category_id).of_type(:integer)}
  end

  describe "Validations" do
    it "passes if it has unique package_type" do
      package_category = create(:package_category, :with_package_type)
      package_type = build(:package_type)
      package_categories_package_type = build(:package_categories_package_type,
        package_type: package_type, package_category: package_category)
      expect(package_categories_package_type.save).to be(true)
    end

    it "fails if package_types is already present" do
      package_category = create(:package_category, :with_package_type)
      package_type = package_category.package_types.last
      package_categories_package_type = build(:package_categories_package_type,
        package_type: package_type, package_category: package_category)
      error = {:package_type_id=>["has already been taken"]}
      expect(package_categories_package_type.save).to be(false)
      expect(package_categories_package_type.errors.messages).to include(error)
    end
  end

end
