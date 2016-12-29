require 'rails_helper'

RSpec.describe PackagesLocation, type: :model do
  describe "Associations" do
    it { is_expected.to belong_to :location }
    it { is_expected.to belong_to :package }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:package_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:location_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:quantity).of_type(:integer)}
  end
end
