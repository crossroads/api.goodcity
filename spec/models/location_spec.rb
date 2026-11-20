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

  describe 'retiring' do
    let(:location) { create :location, building: "MOD-RET", area: "1" }

    it { is_expected.to have_db_column(:retired_at).of_type(:datetime) }

    it 'retired=true stamps retired_at; retired=false clears it' do
      location.update!(retired: true)
      expect(location.reload.retired_at).to be_present
      expect(location).to be_retired
      location.update!(retired: "false")
      expect(location.reload.retired_at).to be_nil
      expect(location).not_to be_retired
    end

    it 'retiring an already-retired location keeps its stamp' do
      stamp = 3.days.ago.change(usec: 0)
      location.update_column(:retired_at, stamp)
      location.reload.update!(retired: "true")
      expect(location.reload.retired_at).to eq(stamp)
    end

    it '.not_retired leaves retired locations out' do
      live = create :location, building: "MOD-LIVE", area: "1"
      location.update!(retired: true)
      expect(Location.not_retired).to include(live)
      expect(Location.not_retired).not_to include(location)
    end
  end

  describe 'in use' do
    let(:location) { create :location, building: "MOD-USE", area: "1" }

    it 'is false for a location nothing points at' do
      expect(location.in_use?).to eq(false)
      expect(Location.in_use_ids).not_to include(location.id)
    end

    it 'is true once its stock history points at it, and in_use_ids agrees' do
      create(:packages_inventory, location: location)
      expect(location.in_use?).to eq(true)
      expect(Location.in_use_ids).to include(location.id)
    end
  end
end
