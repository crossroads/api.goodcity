require 'rails_helper'

RSpec.describe StocktakeRevision, type: :model do
  let(:location) { create(:location) }
  let(:location_2) { create(:location) }
  let(:package) { create(:package) }
  let(:stocktake) { create(:stocktake, location: location) }
  let(:stocktake_revision) { create(:stocktake_revision, stocktake: stocktake, package: package) }

  before { initialize_inventory(package, location: location) }

  describe 'Associations' do
    it { is_expected.to belong_to :package }
    it { is_expected.to belong_to :stocktake }
  end

  describe 'Columns' do
    it { is_expected.to have_db_column(:stocktake_id).of_type(:integer) }
    it { is_expected.to have_db_column(:package_id).of_type(:integer) }
    it { is_expected.to have_db_column(:warning).of_type(:string) }
    it { is_expected.to have_db_column(:state).of_type(:string) }
    it { is_expected.to have_db_column(:quantity).of_type(:integer) }
    it { is_expected.to have_db_column(:dirty).of_type(:boolean) }
  end

  describe "Validations" do
    it { is_expected.to_not allow_value(-1).for(:quantity) }
  end

  describe 'Lifecycle' do
    it "sets the revision as dirty when a package quantity is modified at the stocktakes's location" do
      expect {
        Package::Operations::register_gain(package, quantity: 10, location: location)
      }.to change {
        stocktake_revision.reload.dirty
      }.from(false).to(true)
    end

    it "doesn't set the revision as dirty when a package quantity is modified at a different location" do
      expect {
        Package::Operations::register_gain(package, quantity: 10, location: location_2)
      }.not_to change {
        stocktake_revision.reload.dirty
      }
    end

    it "unsets the dirty flag on save" do
      stocktake_revision.update(dirty: true)

      expect {
        stocktake_revision.update(quantity: 888)
      }.to change { 
        stocktake_revision.reload.dirty
      }.from(true).to(false)
    end
  end
end
