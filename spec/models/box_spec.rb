require 'rails_helper'

RSpec.describe Box, type: :model do

  describe 'Association' do
    it { is_expected.to belong_to :pallet }
    it { is_expected.to have_many :packages }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:box_number).of_type(:string)}
    it{ is_expected.to have_db_column(:description).of_type(:string)}
    it{ is_expected.to have_db_column(:comments).of_type(:text)}
    it{ is_expected.to have_db_column(:pallet_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:stockit_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:created_at).of_type(:datetime)}
    it{ is_expected.to have_db_column(:updated_at).of_type(:datetime)}
  end
end
