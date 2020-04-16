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

      ['dispatch', 'inventory', 'loss', 'gain', 'move'].each do |act|
        expect {
          build(:packages_inventory, act.to_sym).sneaky(:save)
        }.not_to raise_error
      end
    end

    it 'prevents zero quantities' do
      expect {
        create(:packages_inventory, action: 'gain', quantity: 0)
      } .to raise_error(ActiveRecord::RecordInvalid, 'Validation failed: Errors Zero is not a valid change record')
    end

    it 'prevents negative quantities for incremental actions' do
      PackagesInventory::INCREMENTAL_ACTIONS.each do |act|
        expect {
          create(:packages_inventory, action: act, quantity: -1)
        }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Errors Negative values are not allowed for #{act} actions")
      end
    end

    it 'prevents positive quantities for decremental actions' do
      PackagesInventory::DECREMENTAL_ACTIONS.each do |act|
        expect {
          create(:packages_inventory, action: act, quantity: 1)
        }.to raise_error(ActiveRecord::RecordInvalid, /Positive values are not allowed for #{act} actions/)
      end
    end

    it 'prevents removing less than is available at a location' do
      pkg = create(:packages_inventory, action: 'inventory', quantity: 5).package
      PackagesInventory::DECREMENTAL_ACTIONS.each do |act|
        expect {
          create(:packages_inventory, action: act, quantity: -6, package: pkg)
        }.to raise_error(ActiveRecord::RecordInvalid, /Required quantity not present at location/)
      end
    end

    context 'per storage types' do
      before { create(:goodcity_setting, key: "stock.enable_box_pallet_creation", value: "true") }

      let(:pallet_storage) { create(:storage_type, :with_pallet) }
      let(:box_storage) { create(:storage_type, :with_box) }
      let(:box) { create(:package, storage_type: box_storage) }
      let(:pallet) { create(:package, storage_type: pallet_storage) }
      let(:location) { create(:location) }

      it "should prevent increasing the quantity of a box" do
        initialize_inventory(box)

        pi = build(:packages_inventory, package: box, action: 'gain', quantity: 1, location: location)
        pi.save

        expect(pi.persisted?).to eq(false)
        expect(pi.errors.messages).to eq({:errors=>["Inventory action gain is not permitted on Box types"]})
      end

      it "should prevent increasing the quantity of a pallet" do
        initialize_inventory(pallet)

        pi = build(:packages_inventory, package: pallet, action: 'gain', quantity: 1, location: location)
        pi.save

        expect(pi.persisted?).to eq(false)
        expect(pi.errors.messages).to eq({:errors=>["Inventory action gain is not permitted on Pallet types"]})
      end

      it "should prevent inventorizing a box with a quantity > 1" do
        pi = build(:packages_inventory, package: box, action: 'inventory', quantity: 2, location: location)
        pi.save

        expect(pi.persisted?).to eq(false)
        expect(pi.errors.messages).to eq({:errors=>["A Box is limited to a quantity of 1"]})
      end

      it "should prevent inventorizing a box with a quantity > 1" do
        pi = build(:packages_inventory, package: pallet, action: 'inventory', quantity: 2, location: location)
        pi.save

        expect(pi.persisted?).to eq(false)
        expect(pi.errors.messages).to eq({:errors=>["A Pallet is limited to a quantity of 1"]})
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

  describe 'Undo feature' do
    let(:package) { create :package, received_quantity: 5 }
    let(:source) { create :orders_package, package: package, quantity: 5 }
    let(:location) { create :location }

    before { initialize_inventory(package, location: location) }

    it 'allows undoing and redoing dispatch/undispatch actions' do
      action = create(:packages_inventory, action: 'dispatch', quantity: -5, package: package, location: location, source: source)
      undo_action = action.undo
      expect(undo_action.action).to eq('undispatch')
      expect(undo_action.quantity).to eq(5)
      expect(undo_action.location).to eq(location)
      expect(undo_action.source).to eq(source)

      redo_action = undo_action.undo
      expect(redo_action.action).to eq('dispatch')
      expect(redo_action.quantity).to eq(-5)
      expect(redo_action.location).to eq(location)
      expect(redo_action.source).to eq(source)
    end

    it 'allows undoing and redoing gain/loss actions' do
      action = create(:packages_inventory, action: 'gain', quantity: 5, package: package, location: location, source: source)
      undo_action = action.undo
      expect(undo_action.action).to eq('loss')
      expect(undo_action.quantity).to eq(-5)
      expect(undo_action.location).to eq(location)
      expect(undo_action.source).to eq(source)

      redo_action = undo_action.undo
      expect(redo_action.action).to eq('gain')
      expect(redo_action.quantity).to eq(5)
      expect(redo_action.location).to eq(location)
      expect(redo_action.source).to eq(source)
    end

    it 'allows undoing and redoing inventory/uninventory actions' do
      action = create(:packages_inventory, action: 'inventory', quantity: 5, package: package, location: location, source: source)
      undo_action = action.undo
      expect(undo_action.action).to eq('uninventory')
      expect(undo_action.quantity).to eq(-5)
      expect(undo_action.location).to eq(location)
      expect(undo_action.source).to eq(source)

      redo_action = undo_action.undo
      expect(redo_action.action).to eq('inventory')
      expect(redo_action.quantity).to eq(5)
      expect(redo_action.location).to eq(location)
      expect(redo_action.source).to eq(source)
    end

    it 'prevents us from un-doing a move action' do
      # Moves come in pairs, therefore it does not make sense to undo a single record
      action = create(:packages_inventory, action: 'move', quantity: 5, package: package, location: location)
      expect { action.undo }.to raise_error(Goodcity::InventoryError).with_message('Action cannot be undone')
    end
  end

  describe 'Boxing methods' do
    let(:user) { create :user }
    let(:box_type) { create :storage_type, :with_box }
    let(:location) { create :location }
    let(:package1) { create :package, received_quantity: 5 }
    let(:package2) { create :package, received_quantity: 5 }
    let(:box1) { create :package, storage_type: box_type }
    let(:box2) { create :package, storage_type: box_type }

    before do
      create(:goodcity_setting, key: "stock.enable_box_pallet_creation", value: "true")
      create(:goodcity_setting, key: "stock.allow_box_pallet_item_addition", value: "true")
      initialize_inventory(package1, package2, box1, box2, location: location)
    end

    before(:each) do
      expect(PackagesInventory::Computer.package_quantity(package1)).to eq(5)
      expect(PackagesInventory::Computer.package_quantity(package2)).to eq(5)
      expect(PackagesInventory::Computer.package_quantity(box1)).to eq(1)
    end

    def pack(qty, package, into:)
      Package::Operations.pack_or_unpack(container: into, package: package, location_id: location.id, quantity: qty, user_id: user.id, task: 'pack')
    end

    def unpack(qty, package, out_of:)
      Package::Operations.pack_or_unpack(container: out_of, package: package, location_id: location.id, quantity: qty, user_id: user.id, task: 'unpack')
    end

    context 'getting the packages contained in a box' do

      before do
        pack(2, package1, into: box1)
        pack(2, package2, into: box1)
      end

      it 'returns the packages in the box' do
        expect(PackagesInventory::Computer.package_quantity(package1)).to eq(3)
        expect(PackagesInventory::Computer.package_quantity(package2)).to eq(3)

        expect(PackagesInventory.packages_contained_in(box1)).to eq([
          package1,
          package2
        ])
      end

      it 'doesnt return the packages that have been taken out of the box' do
        unpack(2, package1, out_of: box1);

        expect(PackagesInventory::Computer.package_quantity(package1)).to eq(5)
        expect(PackagesInventory::Computer.package_quantity(package2)).to eq(3)

        expect(PackagesInventory.packages_contained_in(box1)).to eq([
          package2
        ])
      end
    end

    context 'getting the containers of a  package' do

      before do
        pack(2, package1, into: box1)
        pack(2, package1, into: box2)
      end

      it 'returns the boxes containing the package' do
        expect(PackagesInventory::Computer.package_quantity(package1)).to eq(1)
        expect(PackagesInventory.containers_of(package1)).to eq([ box1, box2 ])
      end

      it 'doesnt return the boxes that we took the package out of' do
        unpack(2, package1, out_of: box1);

        expect(PackagesInventory::Computer.package_quantity(package1)).to eq(3)
        expect(PackagesInventory.containers_of(package1)).to eq([ box2 ])
      end
    end
  end

  describe 'Computations' do
    let(:package1) { create :package }
    let(:package2) { create :package }
    let(:location1) { create :location, building: 55 }
    let(:location2) { create :location, building: 56 }
    let(:location3) { create :location, building: 57 }
    let(:cpu) { PackagesInventory::Computer }

    before do
      Timestamps.without_timestamping_of PackagesInventory do
        [
          { action: 'inventory', quantity: 100, created_at: 6.months.ago, package: package2, location: location1 },
          { action: 'inventory', quantity: 5, created_at: 5.months.ago, package: package1, location: location1 },
          { action: 'gain', quantity: 3, created_at: 4.months.ago, package: package1, location: location2 },
          { action: 'gain', quantity: 2, created_at: 3.months.ago, package: package1, location: location2 },
          { action: 'dispatch', quantity: -1, created_at: 1.months.ago, package: package1, location: location1 },
          { action: 'loss', quantity: -1, created_at: 1.months.ago, package: package1, location: location1 },
          { action: 'gain', quantity: 2, created_at: 1.week.ago, package: package1, location: location1 },
          { action: 'gain', quantity: 43, created_at: 1.week.ago, package: package2, location: location3 }
        ].each do |params|
          create(:packages_inventory, params)
        end
      end
    end

    context 'Current quantities' do
      context 'by package' do
        it { expect(cpu.package_quantity(package1)).to eq(10) }
        it { expect(cpu.package_quantity(package2)).to eq(143) }
      end

      context 'by location' do
        it { expect(cpu.location_quantity(location1)).to eq(105) }
        it { expect(cpu.location_quantity(location2)).to eq(5) }
      end

      context 'by action' do
        it { expect(cpu.dispatched_quantity).to eq(1) }
      end
    end

    context 'Historical quantities' do
      context 'by package' do
        it { expect(cpu.historical_quantity.where(package: package1).as_of(3.years.ago)).to eq(0) }
        it { expect(cpu.historical_quantity.where(package: package1).as_of(5.months.ago)).to eq(5) }
        it { expect(cpu.historical_quantity.where(package: package1).as_of(3.months.ago)).to eq(10) }
        it { expect(cpu.historical_quantity.where(package: package1).as_of(Time.now)).to eq(10) }
        it { expect(cpu.historical_quantity.where(package: package1).as_of_now).to eq(10) }

        it { expect(cpu.historical_quantity.where(package: package2).as_of(7.months.ago)).to eq(0) }
        it { expect(cpu.historical_quantity.where(package: package2).as_of(6.months.ago)).to eq(100) }
        it { expect(cpu.historical_quantity.where(package: package2).as_of(2.weeks.ago)).to eq(100) }
        it { expect(cpu.historical_quantity.where(package: package2).as_of(1.week.ago)).to eq(143) }
        it { expect(cpu.historical_quantity.where(package: package2).as_of(Time.now)).to eq(143) }
        it { expect(cpu.historical_quantity.where(package: package2).as_of_now).to eq(143) }
      end

      context 'by location' do
        it { expect(cpu.historical_quantity.where(location: location1).as_of(3.years.ago)).to eq(0) }
        it { expect(cpu.historical_quantity.where(location: location1).as_of(6.months.ago)).to eq(100) }
        it { expect(cpu.historical_quantity.where(location: location1).as_of(5.months.ago)).to eq(105) }
        it { expect(cpu.historical_quantity.where(location: location1).as_of(1.month.ago)).to eq(103) }
        it { expect(cpu.historical_quantity.where(location: location1).as_of(1.week.ago)).to eq(105) }
        it { expect(cpu.historical_quantity.where(location: location1).as_of(Time.now)).to eq(105) }
        it { expect(cpu.historical_quantity.where(location: location1).as_of_now).to eq(105) }
      end

      context 'by action' do
         timestamps = [
            "6.months.ago",
            "5.months.ago",
            "4.months.ago",
            "3.months.ago",
            "1.month.ago",
            "1.week.ago"
         ]
        expectations = {
          inventory:  [100, 105,  105,  105,  105,  105],
          dispatch:   [0,   0,    0,    0,    1,    1],
          gain:       [0,   0,    3,    5,    5,    50],
          loss:       [0,   0,    0,    0,    1,    1]
        }

        expectations.each do |action, values|
          values.each_with_index do |val, idx|
            time_ago = timestamps[idx]
            it "computes a quantity of #{val} for #{action}@#{time_ago}" do
              expect(cpu.historical_quantity.where(action: action).as_of(eval(time_ago))).to eq(val)
            end
          end
        end
      end
    end

    context 'Designated quantity' do
      before do
        create(:orders_package, :with_inventory_record, :with_state_dispatched, quantity: 1, package: package1)
        create(:orders_package, :with_state_designated, quantity: 2, package: package1)
        create(:orders_package, :with_state_designated, quantity: 1, package: package1)
      end

      it { expect(cpu.designated_quantity_of(package1)).to eq(3) }
    end

    context 'Dispatched quantity' do
      let(:orders_package_1) { create(:orders_package, :with_state_designated, quantity: 3, package: package2) }
      let(:orders_package_2) { create(:orders_package, :with_state_designated, quantity: 3, package: package2) }

      before do
        touch(orders_package_1, orders_package_2)
        create(:packages_inventory, action: 'dispatch', source: orders_package_1, quantity: -2, package: package2, location: location1)
        create(:packages_inventory, action: 'dispatch', source: orders_package_2, quantity: -2, package: package2, location: location1)
        create(:packages_inventory, action: 'undispatch', source: orders_package_2, quantity: 1, package: package2, location: location1)
      end

      it { expect(cpu.dispatched_quantity(package: package2)).to eq(3) }
      it { expect(cpu.dispatched_quantity(orders_package: orders_package_1)).to eq(2) }
      it { expect(cpu.dispatched_quantity(orders_package: orders_package_2)).to eq(1) }
    end

    context 'Available quantity' do
      before do
        create(:orders_package, :with_state_designated, quantity: 2, package: package1)
        create(:orders_package, :with_state_designated, quantity: 1, package: package1)
      end

      it { expect(cpu.package_quantity(package1)).to eq(10) }
      it { expect(cpu.designated_quantity_of(package1)).to eq(3) }
      it { expect(cpu.dispatched_quantity(package: package1)).to eq(1) }
      it { expect(cpu.available_quantity_of(package1)).to eq(7) }
    end
  end
end
