require 'rails_helper'

RSpec.describe PackagesInventory, type: :model do
  describe "Database columns" do
    it { is_expected.to have_db_column(:action).of_type(:string) }
    it { is_expected.to have_db_column(:source_type).of_type(:string) }
    it { is_expected.to have_db_column(:source_id).of_type(:integer) }
    it { is_expected.to have_db_column(:location_id).of_type(:integer) }
    it { is_expected.to have_db_column(:package_id).of_type(:integer) }
  end

  describe 'Associations' do
    it { is_expected.to belong_to :package }
    it { is_expected.to belong_to :location }
    it { is_expected.to belong_to :source }
  end

  describe 'Validations' do
    it 'prevents invalid actions' do
      expect {
        create(:packages_inventory, action: 'love')
      }.to raise_error(ActiveRecord::RecordInvalid)

      ['dispatch', 'inventory', 'loss', 'gain'].each do |act|
        expect { create(:packages_inventory, action: act)}.not_to raise_error
      end
    end
  end

  describe 'Immutability' do
    let(:packages_inventory) {
      create(:packages_inventory, action: 'gain')
    }

    it 'prevents updating a record' do
      expect {
        packages_inventory.action = 'loss'
        packages_inventory.save
      }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end

    it 'prevents deleting a record' do
      expect {
        packages_inventory.destroy
      }.to raise_error(ActiveRecord::ReadOnlyRecord)
    end
  end

  describe 'Computations' do
    let(:package1) { create :package }
    let(:package2) { create :package }
    let(:location1) { create :location }
    let(:location2) { create :location }
    let(:cpu) { PackagesInventory::Computer }

    before do
      Timestamps.without_timestamping_of PackagesInventory do
        create(:packages_inventory, action: 'inventory', quantity: 100, created_at: 6.months.ago, package: package2, location: location1)
        create(:packages_inventory, action: 'inventory', quantity: 5, created_at: 5.months.ago, package: package1, location: location1)
        create(:packages_inventory, action: 'gain', quantity: 3, created_at: 4.months.ago, package: package1, location: location2)
        create(:packages_inventory, action: 'gain', quantity: 2, created_at: 3.months.ago, package: package1, location: location2)
        create(:packages_inventory, action: 'dispatch', quantity: -1, created_at: 1.months.ago, package: package1, location: location1)
        create(:packages_inventory, action: 'loss', quantity: -1, created_at: 1.months.ago, package: package1, location: location1)
        create(:packages_inventory, action: 'gain', quantity: 2, created_at: 1.week.ago, package: package1, location: location1)
      end
    end

    it { expect(cpu.package_quantity(package2).now).to eq(100) }
    it { expect(cpu.package_quantity(package1).now).to eq(10) }
    it { expect(cpu.package_quantity(package1).as_of(3.years.ago)).to eq(0) }
    it { expect(cpu.package_quantity(package1).as_of(5.months.ago)).to eq(5) }
    it { expect(cpu.total_quantity.now).to eq(110) }
    it { expect(cpu.total_quantity.now).to eq(110) }
    it { expect(cpu.dispatch_quantity.now.abs).to eq(1) }
    it { expect(cpu.inventory_quantity.now).to eq(105) }
    it { expect(cpu.inventory_quantity.as_of(6.months.ago)).to eq(100) }
    it { expect(cpu.total_quantity.as_of(6.months.ago)).to eq(100) }
    it { expect(cpu.inventory_quantity_of_package(package2).as_of(6.months.ago)).to eq(100) }
    it { expect(cpu.location_quantity(location2).as_of(4.months.ago)).to eq(3) }
    it { expect(cpu.location_quantity(location2).now).to eq(5) }
  end
end
