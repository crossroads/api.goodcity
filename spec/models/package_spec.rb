require 'rails_helper'
require "rspec/mocks/standalone"

RSpec.describe Package, type: :model do

  before(:all) do
    allow_any_instance_of(Package).to receive(:update_client_store)
  end

  let(:package) { create :package }

  describe "Associations" do
    it { is_expected.to belong_to :item }
    it { is_expected.to belong_to :package_type }
  end

  describe 'Database columns' do
    it{ is_expected.to have_db_column(:length).of_type(:integer)}
    it{ is_expected.to have_db_column(:width).of_type(:integer)}
    it{ is_expected.to have_db_column(:height).of_type(:integer)}
    it{ is_expected.to have_db_column(:quantity).of_type(:integer)}
    it{ is_expected.to have_db_column(:notes).of_type(:text)}
    it{ is_expected.to have_db_column(:state).of_type(:string)}
    it{ is_expected.to have_db_column(:received_at).of_type(:datetime)}
    it{ is_expected.to have_db_column(:rejected_at).of_type(:datetime)}
    it{ is_expected.to have_db_column(:designation_name).of_type(:string)}
    it{ is_expected.to have_db_column(:grade).of_type(:string)}
    it{ is_expected.to have_db_column(:donor_condition_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:saleable).of_type(:boolean)}
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:package_type_id) }

    let(:attributes) { [:width, :length, :height] }
    it { attributes.each { |attribute| is_expected.to allow_value(nil).for(attribute) } }

    it do
      [:quantity, :length].each do |attribute|
        is_expected.to_not allow_value(-1).for(attribute)
        is_expected.to_not allow_value(100000000).for(attribute)
        is_expected.to allow_value(rand(1..99999999)).for(attribute)
      end
    end

    it do
      [:width, :height].each do |attribute|
        is_expected.to_not allow_value(0).for(attribute)
        is_expected.to_not allow_value(100000).for(attribute)
        is_expected.to allow_value(rand(1..99999)).for(attribute)
      end
    end
  end

  describe "state" do
    describe "#mark_received" do
      it "should set received_at value" do
        expect{
          package.mark_received
        }.to change(package, :received_at)
        expect(package.state).to eq("received")
      end
    end

    describe "#mark_missing" do
      let(:package) { create :package, :received }
      it "should set received_at value" do
        expect{
          package.mark_missing
        }.to change(package, :received_at).to(nil)
        expect(package.state).to eq("missing")
      end
    end
  end

  describe "add_to_stockit" do
    it "should add API errors to package.errors" do
      api_response = {"errors" => {"code" => "can't be blank"}}
      expect(Stockit::ItemSync).to receive(:create).with(package).and_return(api_response)
      package.add_to_stockit
      expect(package.errors).to include(:code)
    end
  end

  describe "remove_from_stockit" do
    it "should add API errors to package.errors" do
      package.inventory_number = "F12345"
      api_response = {"errors" => {"base" => "already designated"}}
      expect(Stockit::ItemSync).to receive(:delete).with(package.inventory_number).and_return(api_response)
      package.remove_from_stockit
      expect(package.errors).to include(:base)
      expect(package.inventory_number).to_not be_nil
    end

    it "should add set inventory_number to nil" do
      package.inventory_number = "F12345"
      expect(Stockit::ItemSync).to receive(:delete).with(package.inventory_number).and_return({})
      package.remove_from_stockit
      expect(package.errors.full_messages).to eq([])
      expect(package.inventory_number).to be_nil
    end
  end

  describe "#offer" do
    it "should return related offer" do
      package = create :package, :with_item
      expect(package.offer).to eq(package.item.offer)
    end
  end

  context "has_paper_trail" do
    it { is_expected.to be_versioned }
  end

  describe "before_save" do
    it "should set default values" do
      item = create :item
      package = build :package, item: item
      expect {
        package.save
      }.to change(package, :donor_condition).from(nil).to(item.donor_condition)
      expect(package.grade).to eq("B")
      expect(package.saleable).to eq(item.offer.saleable)
    end
  end

  describe 'set_item_id' do

    let(:item) { create :item }

    it 'update set_item_id value on receiving sibling package' do
      package = create :package, :stockit_package, item: item
      sibling_package = create :package, :stockit_package, item: item
      expect(Stockit::ItemSync).to receive(:create).with(sibling_package)

      expect {
        sibling_package.mark_received
        package.reload
      }.to change(package, :set_item_id).from(nil).to(item.id)
    end

    describe 'removing set_item_id from package' do
      let!(:package) { create :package, :with_set_item, item: item }
      let!(:sibling_package) { create :package, :with_set_item, item: item }

      it 'update set_item_id value on missing sibling package' do
        expect(Stockit::ItemSync).to receive(:delete).with(sibling_package.inventory_number)

        expect {
          sibling_package.mark_missing
          package.reload
        }.to change(package, :set_item_id).from(item.id).to(nil)
      end

      describe 'remove_from_set' do
        it 'removes package from set' do
          expect {
            sibling_package.remove_from_set
            package.reload
          }.to change(package, :set_item_id).from(item.id).to(nil)
          expect(sibling_package.set_item_id).to be_nil
        end
      end
    end
  end

  describe 'dispatch_stockit_item' do
    let(:package) { create :package, :with_set_item }
    let!(:location) { create :location, :dispatched }
    let!(:packages_location) { create :packages_location, location: location, package: package}

    it 'set dispatch related details' do
      package.dispatch_stockit_item
      expect(package.locations.first).to eq(location)
      expect(package.stockit_sent_on).to_not be_nil
    end

    it 'update set relation on dispatching single package' do
      sibling_package = create :package, :with_set_item, :package_with_locations, item: package.item
      package.dispatch_stockit_item
      package.save
      expect(package.set_item_id).to be_nil
      expect(sibling_package.reload.set_item_id).to be_nil
    end
  end

  describe '#add_location' do
    it 'adds location to package if not added' do
      location = create :location
      package  = create :package
      package.add_location(location.id)
      expect(package.locations).to include(location)
    end

    it 'do not add location to package if same location already exist' do
      package = create :package, :package_with_locations
      location = package.packages_locations.first.location
      expect(package.add_location(location.id)).to be_nil
      expect(package.locations).to include(location)
    end
  end

  describe '#update_or_create_qty_moved_to_location' do
    let!(:package) { create :package }
    let!(:location) { create :location }

    it 'creates associated packages_location record if we do not have packages_location record with provided location_id' do
      expect{
        package.update_or_create_qty_moved_to_location(location.id, 10)
      }.to change(PackagesLocation, :count).by(1)
    end

    it 'creates associated packages_location record with quantity to move' do
      package.update_or_create_qty_moved_to_location(location.id, 10)
      expect(package.packages_locations.first.quantity).to eq 10
    end

    it 'do not creates packages_location record if packages_location record with provided location id already exist' do
      packages_location = create :packages_location, quantity: 10, location: location, package: package
      expect{
        package.update_or_create_qty_moved_to_location(location.id, 10)
      }.to change(PackagesLocation, :count).by(0)
    end

    it 'updates existing packages_location quantity to with new quantity which is addition of qty to move and packages_location quantity' do
      packages_location = create :packages_location, quantity: 10, location: location, package: package
      package.update_or_create_qty_moved_to_location(location.id, 10)
      expect(packages_location.reload.quantity).to eq 20
    end
  end

  describe '#update_existing_package_location_qty' do
    let!(:package) { create :package, received_quantity: 140, quantity: 140 }
    let!(:packages_location) { create :packages_location, quantity: package.received_quantity, package: package }

    it 'subtracts quantity to move from existing packages location record if record exist' do
      quantity_to_move = 10
      new_quantity     = packages_location.quantity - quantity_to_move
      package.update_existing_package_location_qty(packages_location.id, quantity_to_move)
      expect(packages_location.reload.quantity).to eq new_quantity
    end

    it 'destroys packages_location record if remaining quantity for packages_location is zero' do
      quantity_to_move = package.received_quantity
      new_quantity     = packages_location.quantity - quantity_to_move
      expect{
        package.update_existing_package_location_qty(packages_location.id, quantity_to_move)
      }.to change(PackagesLocation, :count).by(-1)
    end
  end

  describe '#add_location' do
    let!(:package) { create :package }
    let!(:location) { create :location }

    it 'creates new packages_location record with provided location id if it do not exist' do
      expect{
        package.add_location(location.id)
      }.to change(PackagesLocation, :count).by(1)
    end

    it 'do not create packages_location record with provided location if already exist' do
      packages_location = create :packages_location, package: package, location: location
      expect{
        package.add_location(location.id)
      }.to change(PackagesLocation, :count).by(0)
    end
  end

  describe '#move_full_quantity' do
    let!(:package) { create :package }
    let!(:location) { create :location }
    let!(:order) { create :order, state: "submitted"}
    let!(:orders_package) { create :orders_package, package: package, state: 'designated', order: order, quantity: 10 }
    let!(:packages_location) { create :packages_location, package: package, reference_to_orders_package: orders_package.id}

    context 'if no packages_location record exist with provided location_id' do
      it 'updates quantity of packages_location record with referenced orders package quantity' do
        package.move_full_quantity(location.id, orders_package.id)
        expect(packages_location.reload.quantity).to eq orders_package.quantity
      end

      it 'updates location_id of packages_location record with provided location_id' do
        package.move_full_quantity(location.id, orders_package.id)
        expect(packages_location.reload.location).to eq location
      end

      it 'clears reference_to_orders_package' do
        package.move_full_quantity(location.id, orders_package.id)
        expect(packages_location.reload.reference_to_orders_package).to be_nil
      end
    end

    context 'if packages_location record already exist with provided location_id' do
      let!(:packages_location_1) { create :packages_location, package: package, reference_to_orders_package: orders_package.id, location: location}

      it 'adds up orders_package quantity and packages_location quantity and updates packages_location quantity with new quantity' do
        new_quantity = packages_location_1.quantity + orders_package.quantity
        package.move_full_quantity(location.id, orders_package.id)
        expect(packages_location_1.reload.quantity).to eq new_quantity
      end

      it 'destroys referenced packages_location' do
        expect{
          package.move_full_quantity(location.id, orders_package.id)
        }.to change(PackagesLocation, :count).by(-1)
      end

      it 'clears reference_to_orders_package' do
        package.move_full_quantity(location.id, orders_package.id)
        expect(packages_location_1.reload.reference_to_orders_package).to be_nil
      end
    end
  end

  describe '#move_partial_quantity' do
    let!(:package) { create :package }
    let!(:location) { create :location }
    let!(:location_1) { create :location }
    let!(:packages_location) { create :packages_location, quantity: 12, package: package, location: location_1 }

    context 'moving some qty to location for which associated packages_location do not exist' do
      it 'subtract quantity to move from packages_location record(current location)' do
        quantity_to_move = 5
        package_qty_changes = [{packages_location_id: packages_location.id, package_id: package.id, new_qty: quantity_to_move}].to_json
        quantity_for_current_location = packages_location.quantity - quantity_to_move
        package.move_partial_quantity(location.id, package_qty_changes, 7)
        expect(packages_location.reload.quantity).to eq quantity_for_current_location
      end

      it 'destroys packages_location record if remaining qty is zero' do
        quantity_to_move = packages_location.quantity
        package_qty_changes = [{packages_location_id: packages_location.id, package_id: package.id, new_qty: quantity_to_move}].to_json
        package.move_partial_quantity(location.id, package_qty_changes, quantity_to_move)
        expect(PackagesLocation.find_by_id(packages_location.id)).to eq nil
      end

      it 'creates new packages_location record with new location id' do
        quantity_to_move = packages_location.quantity
        package_qty_changes = [{packages_location_id: packages_location.id, package_id: package.id, new_qty: quantity_to_move}].to_json
        package.move_partial_quantity(location.id, package_qty_changes, quantity_to_move)
        expect(package.packages_locations.last.location).to eq location
      end

      it 'creates new packages_location record with total qty moved' do
        quantity_to_move = packages_location.quantity
        package_qty_changes = [{packages_location_id: packages_location.id, package_id: package.id, new_qty: quantity_to_move}].to_json
        package.move_partial_quantity(location.id, package_qty_changes, quantity_to_move)
        expect(package.packages_locations.last.quantity).to eq quantity_to_move
      end
    end

    context 'moving qty to location for which associated packages_location record already exist' do
      it 'subtract quantity to move from packages_location record(current location)' do
        packages_location_1 = create :packages_location, package: package, location: location, quantity: 10
        quantity_to_move = 5
        package_qty_changes = [{packages_location_id: packages_location.id, package_id: package.id, new_qty: quantity_to_move}].to_json
        quantity_for_current_location = packages_location.quantity - quantity_to_move
        package.move_partial_quantity(location.id, package_qty_changes, 7)
        expect(packages_location.reload.quantity).to eq quantity_for_current_location
      end

      it "updates existing packages_location quantity with new quantity which is addition of packages_location qty and qty to move" do
        packages_location_1 = create :packages_location, package: package, location: location, quantity: 10
        quantity_to_move = 5
        package_qty_changes = [{packages_location_id: packages_location.id, package_id: package.id, new_qty: quantity_to_move}].to_json
        new_qty = packages_location_1.quantity + quantity_to_move
        package.move_partial_quantity(location.id, package_qty_changes, quantity_to_move)
        expect(packages_location_1.reload.quantity).to eq new_qty
      end
    end

    context 'moving some quantity from multiple locations to location for which packages_location record already exist' do
      let!(:location_2) { create :location }
      let!(:packages_location_2) { create :packages_location, package: package, location: location_2, quantity: 14 }

      it 'subtract quantity moved from original packages_location record associated with locations' do
        quantity_to_move = 5
        resultant_package_location_qty = packages_location.quantity - quantity_to_move
        resultant_package_location_2_qty = packages_location_2.quantity - quantity_to_move
        package_qty_changes = [{packages_location_id: packages_location.id, package_id: package.id,
          new_qty: quantity_to_move}, {packages_location_id: packages_location_2.id,
          package_id: package.id, new_qty: quantity_to_move}].to_json
        package.move_partial_quantity(location.id, package_qty_changes, quantity_to_move)
        expect(packages_location.reload.quantity).to eq resultant_package_location_qty
        expect(packages_location_2.reload.quantity).to eq resultant_package_location_2_qty
      end

      it 'do not creates new packages_location record and updates existing with total qty' do
        packages_location_3 = create :packages_location, package: package, location: location, quantity: 10
        total_qty        = 10
        quantity_to_move = 5
        new_qty          = packages_location_3.quantity + total_qty
        package_qty_changes = [{packages_location_id: packages_location.id, package_id: package.id,
          new_qty: quantity_to_move}, {packages_location_id: packages_location_2.id,
          package_id: package.id, new_qty: quantity_to_move}].to_json
        expect{
          package.move_partial_quantity(location.id, package_qty_changes, total_qty)
        }.to change(PackagesLocation, :count).by(0)
        expect(packages_location_3.reload.quantity).to eq new_qty
      end
    end

    context 'moving some quantity from multiple locations to location for which packages_location do not exist' do
      let!(:location_2) { create :location }
      let!(:packages_location_2) { create :packages_location, package: package, location: location_2, quantity: 14 }

      it 'subtract quantity moved from original packages_location record associated with locations' do
        quantity_to_move = 5
        resultant_package_location_qty = packages_location.quantity - quantity_to_move
        resultant_package_location_2_qty = packages_location_2.quantity - quantity_to_move
        package_qty_changes = [{packages_location_id: packages_location.id, package_id: package.id,
          new_qty: quantity_to_move}, {packages_location_id: packages_location_2.id,
          package_id: package.id, new_qty: quantity_to_move}].to_json
        package.move_partial_quantity(location.id, package_qty_changes, quantity_to_move)
        expect(packages_location.reload.quantity).to eq resultant_package_location_qty
        expect(packages_location_2.reload.quantity).to eq resultant_package_location_2_qty
      end

      it 'do not creates new packages_location record and updates existing with total qty' do
        total_qty        = 10
        quantity_to_move = 5
        package_qty_changes = [{packages_location_id: packages_location.id, package_id: package.id,
          new_qty: quantity_to_move}, {packages_location_id: packages_location_2.id,
          package_id: package.id, new_qty: quantity_to_move}].to_json
        expect{
          package.move_partial_quantity(location.id, package_qty_changes, total_qty)
        }.to change(PackagesLocation, :count).by(1)
        expect(package.packages_locations.reload.last.quantity).to eq total_qty
      end
    end
  end
end

