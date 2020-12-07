require 'rails_helper'

RSpec.describe UserFavourite, type: :model do
  let(:user) { create :user }

  describe "Associations" do
    it { is_expected.to belong_to :favourite }
    it { is_expected.to belong_to :user }
  end

  describe 'Database columns' do
    it { is_expected.to have_db_column(:favourite_type).of_type(:string) }
    it { is_expected.to have_db_column(:favourite_id).of_type(:integer) }
    it { is_expected.to have_db_column(:persistent).of_type(:boolean) }
  end
end
