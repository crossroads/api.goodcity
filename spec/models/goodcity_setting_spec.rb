require 'rails_helper'

RSpec.describe GoodcitySetting, type: :model do
  describe 'Database columns' do
    it{ is_expected.to have_db_column(:key).of_type(:string)}
    it{ is_expected.to have_db_column(:value).of_type(:string)}
    it{ is_expected.to have_db_column(:desc).of_type(:string)}
  end

  describe 'Validations' do
    it { is_expected.to validate_uniqueness_of(:key) }
    it { is_expected.to validate_presence_of(:key) }
  end
end
