require 'rails_helper'

RSpec.describe Stocktake, type: :model do
  describe 'Associations' do
    it { is_expected.to have_many :stocktake_revisions }
    it { is_expected.to belong_to :location }
  end

  describe 'Columns' do
    it { is_expected.to have_db_column(:location_id).of_type(:integer) }
    it { is_expected.to have_db_column(:name).of_type(:string) }
    it { is_expected.to have_db_column(:state).of_type(:string) }
  end

  describe 'Populating revisions' do
    let(:location) { create(:location) }
    let(:packages) { (1..3).map { create(:package, received_quantity: 10) } }
    let(:other_location) { create(:location) }
    let(:other_packages) { (1..3).map { create(:package, received_quantity: 10) } }
    let(:stocktake) { create(:stocktake, location: location) }

    before do
      initialize_inventory(packages, location: location)
      initialize_inventory(other_packages, location: other_location)
      touch(stocktake)
    end

    it "adds revisions for every package in the stocktake's location" do
      expect {
        stocktake.populate_revisions!
      }.to change(StocktakeRevision, :count).from(0).to(3)

      stocktake.reload

      expect(stocktake.revisions.map(&:package_id)).to eq(packages.map(&:id))
      expect(stocktake.revisions.map(&:dirty).uniq).to eq([true])
      expect(stocktake.revisions.map(&:quantity).uniq).to eq([0])
      expect(stocktake.revisions.map(&:state).uniq).to eq(['pending'])
    end

    it "doesn't modify an existing revision for a package" do
      create(:stocktake_revision, package: packages.first, stocktake: stocktake, quantity: 5, dirty: false, state: 'processed')

      expect {
        stocktake.populate_revisions!
      }.to change(StocktakeRevision, :count).from(1).to(3)

      stocktake.reload

      expect(stocktake.revisions.map(&:package_id)).to eq(packages.map(&:id))
      expect(stocktake.revisions.map(&:dirty).uniq).to eq([false, true])
      expect(stocktake.revisions.map(&:quantity).uniq).to eq([5, 0])
      expect(stocktake.revisions.map(&:state).uniq).to eq(['processed', 'pending'])
    end
  end
end
