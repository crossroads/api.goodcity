require 'rails_helper'

RSpec.describe BookingType, type: :model do
  describe "Associations" do
    it { is_expected.to have_many :orders }
  end

  describe 'Database columns' do
    it { is_expected.to have_db_column(:name_en).of_type(:string) }
    it { is_expected.to have_db_column(:name_zh_tw).of_type(:string) }
    it { is_expected.to have_db_column(:identifier).of_type(:string) }
  end

  describe "Validations" do
    it { is_expected.to validate_uniqueness_of(:identifier) }
    it { is_expected.to validate_uniqueness_of(:name_en) }
    it { is_expected.to validate_uniqueness_of(:name_zh_tw) }
  end
end
