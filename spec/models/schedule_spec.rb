require 'rails_helper'

RSpec.describe Schedule, type: :model do

  describe 'Association' do
    it { is_expected.to have_many :deliveries }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:resource).of_type(:string)}
    it{ is_expected.to have_db_column(:slot).of_type(:integer)}
    it{ is_expected.to have_db_column(:slot_name).of_type(:string)}
    it{ is_expected.to have_db_column(:zone).of_type(:string)}
    it{ is_expected.to have_db_column(:scheduled_at).of_type(:datetime)}
  end

  context "has_paper_trail" do
    it { is_expected.to be_versioned }
  end
end
