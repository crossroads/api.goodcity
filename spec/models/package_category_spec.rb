require 'rails_helper'

RSpec.describe PackageCategory, type: :model do
  describe 'Association' do
    it { is_expected.to have_many :package_categories_package_types }
    it { is_expected.to have_many :package_types }
    it { is_expected.to have_many :child_categories }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:name_en).of_type(:string)}
    it{ is_expected.to have_db_column(:name_zh_tw).of_type(:string)}
    it{ is_expected.to have_db_column(:parent_id).of_type(:integer)}
  end
end
