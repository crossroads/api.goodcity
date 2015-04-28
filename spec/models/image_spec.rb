require 'rails_helper'

RSpec.describe Image, type: :model do

  describe 'Associations' do
    it { is_expected.to belong_to :item }
  end

  describe 'Database Columns' do
    it { is_expected.to have_db_column(:cloudinary_id).of_type(:string) }
    it { is_expected.to have_db_column(:favourite).of_type(:boolean) }
    it { is_expected.to have_db_column(:item_id).of_type(:integer) }
  end
  context "has_paper_trail" do
    it { is_expected.to respond_to(:versions) }
  end
end
