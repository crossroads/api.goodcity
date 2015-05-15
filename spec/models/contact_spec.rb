require 'rails_helper'

RSpec.describe Contact, type: :model do
  describe 'Association' do
    it { is_expected.to have_one :address }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:name).of_type(:string)}
    it{ is_expected.to have_db_column(:mobile).of_type(:string)}
  end

  context "has_paper_trail" do
    it { is_expected.to be_versioned }
  end
end
