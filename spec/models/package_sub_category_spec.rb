require 'rails_helper'

RSpec.describe PackageSubCategory, type: :model do
  describe 'Association' do
    it { is_expected.to belong_to :package_category }
    it { is_expected.to belong_to :package_type }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:package_type_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:package_category_id).of_type(:integer)}
  end
end
