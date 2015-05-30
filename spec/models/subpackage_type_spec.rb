require 'rails_helper'

RSpec.describe SubpackageType, type: :model do
  describe "Associations" do
    it { is_expected.to belong_to :package_type }
    it { is_expected.to belong_to :child_package_type }
  end

  describe "Database columns" do
    it { is_expected.to have_db_column(:package_type_id).of_type(:integer) }
    it { is_expected.to have_db_column(:subpackage_type_id).of_type(:integer) }
    it { is_expected.to have_db_column(:is_default).of_type(:boolean) }
  end
end
