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
    it { is_expected.to have_db_column(:comment).of_type(:string) }
    it { is_expected.to have_db_column(:counts).of_type(:integer) }
    it { is_expected.to have_db_column(:gains).of_type(:integer) }
    it { is_expected.to have_db_column(:losses).of_type(:integer) }
    it { is_expected.to have_db_column(:warnings).of_type(:integer) }
  end

  describe 'Counter caches' do
    let(:location) { create(:location) }
    let(:package) { create(:package, received_quantity: 5) }
    let(:stocktake) { create(:stocktake, location: location) }
  
    before { initialize_inventory(package, location: location) }

    before do
      stocktake.compute_counters!
    end

    it "adds to the gains counter if a revision has a quantity greater than the packages on_hand_quantity" do
      expect {
        create :stocktake_revision, stocktake: stocktake, package: package, quantity: 6
      }.to change(stocktake, :gains).from(0).to(1)

      expect(stocktake.losses).to eq(0)
      expect(stocktake.warnings).to eq(0)
    end

    it "adds to the counts counter if a revision has a quantity greater than the packages on_hand_quantity" do
      expect {
        create :stocktake_revision, stocktake: stocktake, package: package, quantity: 6
      }.to change(stocktake, :counts).from(0).to(1)

      expect(stocktake.losses).to eq(0)
      expect(stocktake.warnings).to eq(0)
    end

    it "adds to the losses counter if a revision has a quantity lower than the packages on_hand_quantity" do
      expect {
        create :stocktake_revision, stocktake: stocktake, package: package, quantity: 4
      }.to change(stocktake, :losses).from(0).to(1)

      expect(stocktake.gains).to eq(0)
      expect(stocktake.warnings).to eq(0)
    end

    it "adds to the counts counter if a revision has a quantity lower than the packages on_hand_quantity" do
      expect {
        create :stocktake_revision, stocktake: stocktake, package: package, quantity: 4
      }.to change(stocktake, :counts).from(0).to(1)

      expect(stocktake.gains).to eq(0)
      expect(stocktake.warnings).to eq(0)
    end

    it "adds to the warning counter if the revision is dirty" do
      expect {
        create :stocktake_revision, stocktake: stocktake, package: package, quantity: 5, dirty: true
      }.to change(stocktake, :warnings).from(0).to(1)
    end

    it "doesnt add to the counts if the revision is dirty" do
      expect {
        create :stocktake_revision, stocktake: stocktake, package: package, quantity: 5, dirty: true
      }.not_to change(stocktake, :counts)
    end

    it "removes a count if it a revision is changed to be marked as dirty" do
      revision = create(:stocktake_revision, stocktake: stocktake, package: package, quantity: 6)
      expect(stocktake.reload.gains).to eq(1)
      revision.update!(dirty: true)
      expect(stocktake.reload.gains).to eq(0)
    end
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

      expect(stocktake.revisions.map(&:package_id)).to match_array(packages.map(&:id))
      expect(stocktake.revisions.map(&:dirty).uniq).to eq([true])
      expect(stocktake.revisions.map(&:quantity).uniq).to eq([0])
      expect(stocktake.revisions.map(&:state).uniq).to eq(['pending'])
    end

    it "initializes the counter caches" do
      stocktake.populate_revisions!
      stocktake.reload

      expect(stocktake.counts).to eq(0)
      expect(stocktake.gains).to eq(0)
      expect(stocktake.losses).to eq(0)
      expect(stocktake.warnings).to eq(3)
    end

    it "doesn't modify an existing revision for a package" do
      create(:stocktake_revision, package: packages.first, stocktake: stocktake, quantity: 5, dirty: false, state: 'processed')

      expect {
        stocktake.populate_revisions!
      }.to change(StocktakeRevision, :count).from(1).to(3)

      stocktake.reload

      expect(stocktake.revisions.map(&:package_id)).to match_array(packages.map(&:id))
      expect(stocktake.revisions.map(&:dirty).uniq).to eq([false, true])
      expect(stocktake.revisions.map(&:quantity).uniq).to match_array([5, 0])
      expect(stocktake.revisions.map(&:state).uniq).to eq(['processed', 'pending'])
    end
  end
end
