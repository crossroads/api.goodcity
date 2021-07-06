require 'rails_helper'

RSpec.describe Location, type: :model do
  describe 'Associations' do
    it { is_expected.to have_many(:packages).through(:packages_locations) }
  end

  describe 'Database Columns' do
    it { is_expected.to have_db_column(:area).of_type(:string) }
    it { is_expected.to have_db_column(:building).of_type(:string) }
  end

  describe 'class methods' do
    describe '.search' do
      let(:location) { create :location, building: "Central", area: "b" }

      it 'performs case insensitive search for location for matching building' do
        expect(Location.search("cent")).to include(location)
        expect(Location.search("CEntral")).to include(location)
      end

      it 'performs case insensitive search for location for matching area' do
        expect(Location.search("b")).to include(location)
        expect(Location.search("B")).to include(location)
      end
    end
  end
end
