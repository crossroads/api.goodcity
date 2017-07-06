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
    it { is_expected.to have_many :orders_packages }
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
    it{ is_expected.to have_db_column(:received_quantity).of_type(:integer)}
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:package_type_id) }
    it { is_expected.to_not allow_value(-1).for(:quantity) }
    it { is_expected.to_not allow_value(-1).for(:received_quantity) }
    it { is_expected.to_not allow_value(0).for(:received_quantity) }
    it do
      [:width, :height, :length].each do |attribute|
        is_expected.to_not allow_value(-1).for(attribute)
        is_expected.to allow_value(nil).for(attribute)
      end
    end
  end

  describe "state" do
    describe "#mark_received" do
      it "should set received_at value" do
        expect(Stockit::ItemSync).to receive(:create).with(package)
        expect{
          package.mark_received
        }.to change(package, :received_at)
        expect(package.state).to eq("received")
      end
    end

    describe "#mark_missing" do
      let(:package) { create :package, :received }
      it "should set received_at value" do
        expect(Stockit::ItemSync).to receive(:delete).with(package.inventory_number)
        expect{
          package.mark_missing
        }.to change(package, :received_at).to(nil)
        expect(package.state).to eq("missing")
      end
    end
  end

  describe "update_allow_web_publish_to_false" do
    it "should set allow_web_publish=false" do
      @package = create :package, allow_web_publish: true
      @package.update_allow_web_publish_to_false
      expect(@package.allow_web_publish).to eq(false)
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

  describe "after_update" do
    it "#update_packages_location_quantity" do
      @package = create(:package, :received)
      new_quantity = 4
      @packages_location = @package.packages_locations.first
      expect {
        @package.update(received_quantity: new_quantity)
        @packages_location.reload
      }.to change(@packages_location, :quantity).from(@package.received_quantity).to(new_quantity)
    end

    it "#received_quantity_changed_and_locations_exists?" do
      new_quantity = rand(4)+2
      package.update(received_quantity: new_quantity)
      expect(package.received_quantity_changed_and_locations_exists?).to eq(false)
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
    let(:location) { create :location, :dispatched }
    let!(:packages_location) { create :packages_location, location: location, package: package }
    before { expect(Stockit::ItemSync).to receive(:dispatch).with(package) }

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

  describe '#update_or_create_qty_moved_to_location' do
    let!(:package) { create :package }
    let!(:location) { create :location }

    it 'creates associated packages_location record if we do not have packages_location record with provided location_id' do
      expect{
        package.update_or_create_qty_moved_to_location(location.id, 4)
      }.to change(PackagesLocation, :count).by(1)
    end

    it 'creates associated packages_location record with quantity to move' do
      package.update_or_create_qty_moved_to_location(location.id, 4)
      expect(package.packages_locations.first.quantity).to eq 4
    end

    it 'do not creates packages_location record if packages_location record with provided location id already exist' do
      packages_location = create :packages_location, quantity: 4, location: location, package: package
      expect{
        package.update_or_create_qty_moved_to_location(location.id, 4)
      }.to change(PackagesLocation, :count).by(0)
    end

    it 'updates existing packages_location quantity to with new quantity which is addition of qty to move and packages_location quantity' do
      packages_location = create :packages_location, quantity: 2, location: location, package: package
      package.update_or_create_qty_moved_to_location(location.id, 2)
      expect(packages_location.reload.quantity).to eq 4
    end
  end

  describe '#update_existing_package_location_qty' do
    let!(:package) { create :package, received_quantity: 10, quantity: 10 }
    let!(:packages_location) { create :packages_location, quantity: package.received_quantity, package: package }

    it 'subtracts quantity to move from existing packages location record if record exist' do
      quantity_to_move = 8
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

  describe '#build_or_create_packages_location' do
    let!(:package) { create :package }
    let!(:location) { create :location }

    it 'creates new packages_location record with provided location id if it do not exist' do
      expect{
        package.build_or_create_packages_location(location.id, 'create')
      }.to change(PackagesLocation, :count).by(1)
    end

    it 'do not create packages_location record with provided location if already exist' do
      packages_location = create :packages_location, package: package, location: location
      expect{
        package.build_or_create_packages_location(location.id, 'create')
      }.to change(PackagesLocation, :count).by(0)
    end
  end

  describe '#move_full_quantity' do
    let(:package) { create :package }
    let(:location) { create :location }
    let(:order) { create :order, state: "submitted"}
    let!(:orders_package) { create :orders_package, package: package, state: 'designated', order: order, quantity: 1 }
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
    let(:package) { create :package }
    let(:location) { create :location }
    let(:location_1) { create :location }
    let(:packages_location) { create :packages_location, quantity: 4, package: package, location: location_1 }

    context 'moving some qty to location for which associated packages_location do not exist' do
      it 'subtract quantity to move from packages_location record(current location)' do
        quantity_to_move = 2
        package_qty_changes = [{"packages_location_id" => packages_location.id, "package_id" => package.id,
          "new_qty" => quantity_to_move}]
        quantity_for_current_location = packages_location.quantity - quantity_to_move
        package.move_partial_quantity(location.id, package_qty_changes, 2)
        expect(packages_location.reload.quantity).to eq quantity_for_current_location
      end

      it 'destroys packages_location record if remaining qty is zero' do
        quantity_to_move = packages_location.quantity
        package_qty_changes = [{"packages_location_id" => packages_location.id, "package_id" => package.id,
          "new_qty" => quantity_to_move}]
        package.move_partial_quantity(location.id, package_qty_changes, quantity_to_move)
        expect(PackagesLocation.find_by_id(packages_location.id)).to eq nil
      end

      it 'creates new packages_location record with new location id' do
        quantity_to_move = packages_location.quantity
        package_qty_changes = [{"packages_location_id" => packages_location.id, "package_id" => package.id,
          "new_qty" => quantity_to_move}]
        package.move_partial_quantity(location.id, package_qty_changes, quantity_to_move)
        expect(package.packages_locations.last.location).to eq location
      end

      it 'creates new packages_location record with total qty moved' do
        quantity_to_move = packages_location.quantity
        package_qty_changes = [{"packages_location_id" => packages_location.id, "package_id" => package.id,
          "new_qty" => quantity_to_move}]
        package.move_partial_quantity(location.id, package_qty_changes, quantity_to_move)
        expect(package.packages_locations.last.quantity).to eq quantity_to_move
      end
    end

    context 'moving qty to location for which associated packages_location record already exist' do
      let(:package1) { create :package }
      let(:packages_location_1) { create :packages_location, package: package1, location: location, quantity: 4 }
      let(:quantity_to_move) { 1 }

      it 'subtract quantity to move from packages_location record(current location)' do
        package_qty_changes = [{"packages_location_id" => packages_location.id, "package_id" => package.id, "new_qty" => quantity_to_move}]
        quantity_for_current_location = packages_location.quantity - quantity_to_move
        package.move_partial_quantity(location.id, package_qty_changes, 2)
        expect(packages_location.reload.quantity).to eq quantity_for_current_location
      end

      it "updates existing packages_location quantity with new quantity which is addition of packages_location qty and qty to move" do
        package_qty_changes = [{"packages_location_id" => packages_location.id, "package_id" => package.id,
          "new_qty" => quantity_to_move}]
          debugger
        new_qty = packages_location_1.quantity + quantity_to_move
        package1.move_partial_quantity(location.id, package_qty_changes, quantity_to_move)
        debugger
        expect(packages_location_1.reload.quantity).to eq new_qty
      end
    end

    context 'moving some quantity from multiple locations to location for which packages_location record already exist' do
      let(:location_2) { create :location }
      let(:packages_location_2) { create :packages_location, package: package, location: location_2, quantity: 4 }
      let(:quantity_to_move) { 2 }

      it 'subtract quantity moved from original packages_location record associated with locations' do
        resultant_package_location_qty = packages_location.quantity - quantity_to_move
        resultant_package_location_2_qty = packages_location_2.quantity - quantity_to_move
        package_qty_changes = [{"packages_location_id" => packages_location.id, "package_id" => package.id,
          "new_qty" => quantity_to_move}, {"packages_location_id" => packages_location_2.id,
          "package_id" => package.id, "new_qty" => quantity_to_move}]
        package.move_partial_quantity(location.id, package_qty_changes, quantity_to_move)
        expect(packages_location.reload.quantity).to eq resultant_package_location_qty
        expect(packages_location_2.reload.quantity).to eq resultant_package_location_2_qty
      end

      it 'do not creates new packages_location record and updates existing with total qty' do
        packages_location_3 = create :packages_location, package: package, location: location, quantity: 4
        total_qty        = 5
        new_qty          = packages_location_3.quantity + total_qty
        package_qty_changes = [{"packages_location_id" => packages_location.id, "package_id" => package.id,
          "new_qty" => quantity_to_move}, {"packages_location_id" => packages_location_2.id,
          "package_id" => package.id, "new_qty" => quantity_to_move}]
        expect{
          package.move_partial_quantity(location.id, package_qty_changes, total_qty)
        }.to change(PackagesLocation, :count).by(0)
        expect(packages_location_3.reload.quantity).to eq new_qty
      end
    end

    context 'moving some quantity from multiple locations to location for which packages_location do not exist' do
      let(:location_2) { create :location }
      let(:packages_location_2) { create :packages_location, package: package, location: location_2, quantity: 5 }
      let(:quantity_to_move) { 4 }

      it 'subtract quantity moved from original packages_location record associated with locations' do
        resultant_package_location_qty = packages_location.quantity - quantity_to_move
        resultant_package_location_2_qty = packages_location_2.quantity - quantity_to_move
        package_qty_changes = [{"packages_location_id" => packages_location.id, "package_id" => package.id,
          "new_qty" => quantity_to_move}, {"packages_location_id" => packages_location_2.id,
          "package_id" => package.id, "new_qty" => quantity_to_move}]
        package.move_partial_quantity(location.id, package_qty_changes, quantity_to_move)
        expect(packages_location.reload.quantity).to eq resultant_package_location_qty
        expect(packages_location_2.reload.quantity).to eq resultant_package_location_2_qty
      end

      it 'do not creates new packages_location record and updates existing with total qty' do
        total_qty        = 5
        package_qty_changes = [{packages_location_id: packages_location.id, package_id: package.id,
          new_qty: quantity_to_move}, {packages_location_id: packages_location_2.id,
          package_id: package.id, new_qty: quantity_to_move}]
        expect{
          package.move_partial_quantity(location.id, package_qty_changes, total_qty)
        }.to change(PackagesLocation, :count).by(1)
        expect(package.packages_locations.reload.last.quantity).to eq total_qty
      end
    end
  end

  describe '#update_designation' do
    let(:package) { create :package }
    let(:order) { create :order, state: 'submitted' }

    it 'adds order id to package' do
      package.update_designation(order.id)
      expect(package.reload.order_id).to eq order.id
    end
  end

  describe '#remove_designation' do
    let(:package) { create :package, order_id: 1 }

    it 'removes order_id from package record' do
      package.remove_designation
      expect(package.reload.order_id).to eq nil
    end
  end

  describe '#update_in_stock_quantity' do
    let(:package) { create :package, received_quantity: 10 }
    let(:orders_package) { create :orders_package, quantity: 3, package: package, state: 'designated' }

    it 'subtracts assigned qty from received_quantity to calculate in hand quantity and updates package quantity with it' do
      in_hand_quantity = package.received_quantity - orders_package.quantity
      package.reload.update_in_stock_quantity
      expect(package.reload.quantity).to eq in_hand_quantity
    end

    it 'do not change received_quantity' do
      in_hand_quantity  = package.received_quantity - orders_package.quantity
      received_quantity = package.received_quantity
      package.update_in_stock_quantity
      expect(package.reload.received_quantity).to eq received_quantity
    end
  end

  describe '#create_associated_packages_location' do
    let(:package) { create :package }
    let(:location) { create :location }

    it 'creates associated package location record for package' do
      expect{
        package.create_associated_packages_location(location.id, 2)
      }.to change(PackagesLocation, :count).by(1)
    end
  end

  describe '#create_or_update_location_for_dispatch_from_stockit' do
    let(:package) { create :package }
    let(:order) { create :order }
    let(:orders_package) { create :orders_package, state: 'dispatched', package: package, order: order }
    let(:dispatched_location) { create :location, :dispatched }

    it 'updates orders_package_id against packages_location record if dispatched' do
      packages_location = create :packages_location, package: package, location: dispatched_location
      package.create_or_update_location_for_dispatch_from_stockit(dispatched_location, orders_package.id, orders_package.quantity)
      expect(packages_location.reload.reference_to_orders_package).to eq orders_package.id
    end

    it 'creates new packages_location record with orders_package_id if packages_location record do not exist and package dispatched' do
      expect{
        package.create_or_update_location_for_dispatch_from_stockit(dispatched_location, orders_package.id, orders_package.quantity)
      }.to change(PackagesLocation, :count).by(1)
      expect(package.reload.packages_locations.first.reference_to_orders_package).to eq orders_package.id
    end
  end

  describe '#create_dispatched_packages_location_from_gc' do
    let(:dispatched_location) { create :location, :dispatched }
    let(:order) { create :order }
    let(:orders_package) { create :orders_package, state: 'dispatched', package: package, order: order }
    let(:dispatched_location) { create :location, :dispatched }

    it 'creates dispatched packages location record against package if do not exist' do
      expect{
        package.create_dispatched_packages_location_from_gc(dispatched_location, orders_package.id, 1)
      }.to change(PackagesLocation, :count).by(1)
      first_location = package.reload.packages_locations.first
      expect(first_location.location).to eq dispatched_location
      expect(first_location.reference_to_orders_package).to eq orders_package.id
      expect(first_location.quantity).to eq 1
    end

    it 'do not creates dispatched packages_location record if already exists' do
      packages_location = create :packages_location, package: package, location: dispatched_location,
        reference_to_orders_package: orders_package.id
      expect{
        package.create_dispatched_packages_location_from_gc(dispatched_location, orders_package.id, 1)
      }.to change(PackagesLocation, :count).by(0)
    end
  end

  describe '#find_packages_location_with_location_id' do
    let(:package) { create :package }
    let(:location) { create :location }

    it 'returns packages_location record if found with particular location_id' do
      packages_location = create :packages_location, package: package, location: location
      expect(package.find_packages_location_with_location_id(location.id)).to eq packages_location
    end

    it 'returns nil if packages_location record is not available with particular location_id' do
      expect(package.find_packages_location_with_location_id(location.id)).to eq nil
    end
  end
end
