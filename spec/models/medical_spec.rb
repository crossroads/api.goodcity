require 'rails_helper'

RSpec.describe Medical, type: :model do
  describe 'Associations' do
    it { is_expected.to belong_to :country }
  end

  describe 'Database columns' do
    it { is_expected.to have_db_column(:serial_number) }
    it { is_expected.to have_db_column(:brand).of_type(:string) }
    it { is_expected.to have_db_column(:model).of_type(:string) }
    it { is_expected.to have_db_column(:country_id).of_type(:integer) }
    it { is_expected.to have_db_column(:expiry_date).of_type(:date) }
    it { is_expected.to have_db_column(:updated_by_id).of_type(:integer) }
    it { is_expected.to have_db_column(:stockit_id).of_type(:integer) }
  end
end
