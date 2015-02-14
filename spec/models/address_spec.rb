require 'rails_helper'

RSpec.describe Address, type: :model do
  describe 'Association' do
    it { is_expected.to belong_to :district }
    it { is_expected.to belong_to :addressable }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:flat).of_type(:string)}
    it{ is_expected.to have_db_column(:building).of_type(:string)}
    it{ is_expected.to have_db_column(:street).of_type(:string)}
    it{ is_expected.to have_db_column(:district_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:addressable_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:addressable_type).of_type(:string)}
    it{ is_expected.to have_db_column(:address_type).of_type(:string)}
  end
end
