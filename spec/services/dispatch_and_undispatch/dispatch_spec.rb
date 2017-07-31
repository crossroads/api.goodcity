require "rails_helper"

module DispatchAndUndispatch
 describe Dispatch do

  before(:all) do
    @package = create :package, :with_set_item, received_quantity: 140, quantity: 140
    @order   = create :order
    @orders_package = create :orders_package
    @quantity = 2
  end

  describe 'instance methods' do
    subject { described_class.new(@orders_package, @package, @quantity) }

    describe '#new' do
      it 'initializes class variables' do
        expect(subject.package).to eq @package
        expect(subject.orders_package).to eq @orders_package
        expect(subject.package_location_qty).to eq @quantity
      end
    end

    describe 'dispatch_stockit_item' do
      let(:location) { create :location, :dispatched }
      let!(:packages_location) { create :packages_location, location: location, package: @package }
      before { expect(Stockit::ItemSync).to receive(:dispatch).with(@package) }

      it 'set dispatch related details' do
        subject.dispatch_stockit_item
        expect(@package.locations.first).to eq(location)
        expect(@package.stockit_sent_on).to_not be_nil
      end

      it 'update set relation on dispatching single package' do
        sibling_package = create :package, :with_set_item, :package_with_locations, item: @package.item
        subject.dispatch_stockit_item
        @package.save
        expect(@package.set_item_id).to be_nil
        expect(sibling_package.reload.set_item_id).to be_nil
      end
    end

    describe '#update_or_create_qty_moved_to_location' do
      let!(:package) { create :package }
      let!(:location) { create :location }

      it 'creates associated packages_location record if we do not have packages_location record with provided location_id' do
        expect{
          subject.update_or_create_qty_moved_to_location(location.id, 10)
        }.to change(PackagesLocation, :count).by(1)
      end

      it 'creates associated packages_location record with quantity to move' do
        subject.update_or_create_qty_moved_to_location(location.id, 10)
        expect(@package.packages_locations.first.quantity).to eq 10
      end

      it 'do not creates packages_location record if packages_location record with provided location id already exist' do
        packages_location = create :packages_location, quantity: 10, location: location, package: @package
        expect{
          subject.update_or_create_qty_moved_to_location(location.id, 10)
        }.to change(PackagesLocation, :count).by(0)
      end

      it 'updates existing packages_location quantity to with new quantity which is addition of qty to move and packages_location quantity' do
        packages_location = create :packages_location, quantity: 10, location: location, package: @package
        subject.update_or_create_qty_moved_to_location(location.id, 10)
        expect(packages_location.reload.quantity).to eq 20
      end
    end

    describe '#update_existing_package_location_qty' do
      let!(:packages_location) { create :packages_location, quantity: @package.received_quantity, package: @package }

      it 'subtracts quantity to move from existing packages location record if record exist' do
        quantity_to_move = 10
        new_quantity     = packages_location.quantity - quantity_to_move
        subject.update_existing_package_location_qty(packages_location.id, quantity_to_move)
        expect(packages_location.reload.quantity).to eq new_quantity
      end

      it 'destroys packages_location record if remaining quantity for packages_location is zero' do
        quantity_to_move = @package.received_quantity
        new_quantity     = packages_location.quantity - quantity_to_move
        expect{
          subject.update_existing_package_location_qty(packages_location.id, quantity_to_move)
        }.to change(PackagesLocation, :count).by(-1)
      end
    end

    describe '#move_partial_quantity' do
      let(:location) { create :location }
      let(:location_1) { create :location }
      let(:packages_location) { create :packages_location, quantity: 12, package: @package, location: location_1 }

      context 'moving some qty to location for which associated packages_location do not exist' do
        it 'subtract quantity to move from packages_location record(current location)' do
          quantity_to_move = 5
          package_qty_changes = [{"packages_location_id" => packages_location.id, "package_id" => @package.id,
            "new_qty" => quantity_to_move}]
          quantity_for_current_location = packages_location.quantity - quantity_to_move
          subject.move_partial_quantity(location.id, package_qty_changes, 7)
          expect(packages_location.reload.quantity).to eq quantity_for_current_location
        end

        it 'destroys packages_location record if remaining qty is zero' do
          quantity_to_move = packages_location.quantity
          package_qty_changes = [{"packages_location_id" => packages_location.id, "package_id" => @package.id,
            "new_qty" => quantity_to_move}]
          subject.move_partial_quantity(location.id, package_qty_changes, quantity_to_move)
          expect(PackagesLocation.find_by_id(packages_location.id)).to eq nil
        end

        it 'creates new packages_location record with new location id' do
          quantity_to_move = packages_location.quantity
          package_qty_changes = [{"packages_location_id" => packages_location.id, "package_id" => @package.id,
            "new_qty" => quantity_to_move}]
          subject.move_partial_quantity(location.id, package_qty_changes, quantity_to_move)
          expect(@package.packages_locations.last.location).to eq location
        end

        it 'creates new packages_location record with total qty moved' do
          quantity_to_move = packages_location.quantity
          package_qty_changes = [{"packages_location_id" => packages_location.id, "package_id" => @package.id,
            "new_qty" => quantity_to_move}]
          subject.move_partial_quantity(location.id, package_qty_changes, quantity_to_move)
          expect(@package.packages_locations.last.quantity).to eq quantity_to_move
        end
      end

      context 'moving qty to location for which associated packages_location record already exist' do
        let(:packages_location_1) { create :packages_location, package: @package, location: location, quantity: 10 }
        let(:quantity_to_move) { 5 }

        it 'subtract quantity to move from packages_location record(current location)' do
          package_qty_changes = [{"packages_location_id" => packages_location.id, "package_id" => @package.id,
            "new_qty" => quantity_to_move}]
          quantity_for_current_location = packages_location.quantity - quantity_to_move
          subject.move_partial_quantity(location.id, package_qty_changes, 7)
          expect(packages_location.reload.quantity).to eq quantity_for_current_location
        end

        it "updates existing packages_location quantity with new quantity which is addition of packages_location qty and qty to move" do
          package_qty_changes = [{"packages_location_id" => packages_location.id, "package_id" => @package.id,
            "new_qty" => quantity_to_move}]
          new_qty = packages_location_1.quantity + quantity_to_move
          subject.move_partial_quantity(location.id, package_qty_changes, quantity_to_move)
          expect(packages_location_1.reload.quantity).to eq new_qty
        end
      end

      context 'moving some quantity from multiple locations to location for which packages_location record already exist' do
        let(:location_2) { create :location }
        let(:packages_location_2) { create :packages_location, package: @package, location: location_2, quantity: 14 }
        let(:quantity_to_move) { 5 }

        it 'subtract quantity moved from original packages_location record associated with locations' do
          resultant_package_location_qty = packages_location.quantity - quantity_to_move
          resultant_package_location_2_qty = packages_location_2.quantity - quantity_to_move
          package_qty_changes = [{"packages_location_id" => packages_location.id, "package_id" => @package.id,
            "new_qty" => quantity_to_move}, {"packages_location_id" => packages_location_2.id,
            "package_id" => @package.id, "new_qty" => quantity_to_move}]
          subject.move_partial_quantity(location.id, package_qty_changes, quantity_to_move)
          expect(packages_location.reload.quantity).to eq resultant_package_location_qty
          expect(packages_location_2.reload.quantity).to eq resultant_package_location_2_qty
        end

        it 'do not creates new packages_location record and updates existing with total qty' do
          packages_location_3 = create :packages_location, package: @package, location: location, quantity: 10
          total_qty        = 10
          new_qty          = packages_location_3.quantity + total_qty
          package_qty_changes = [{"packages_location_id" => packages_location.id, "package_id" => @package.id,
            "new_qty" => quantity_to_move}, {"packages_location_id" => packages_location_2.id,
            "package_id" => @package.id, "new_qty" => quantity_to_move}]
          expect{
            subject.move_partial_quantity(location.id, package_qty_changes, total_qty)
          }.to change(PackagesLocation, :count).by(0)
          expect(packages_location_3.reload.quantity).to eq new_qty
        end
      end

      context 'moving some quantity from multiple locations to location for which packages_location do not exist' do
        let(:location_2) { create :location }
        let(:packages_location_2) { create :packages_location, package: @package, location: location_2, quantity: 14 }
        let(:quantity_to_move) { 5 }

        it 'subtract quantity moved from original packages_location record associated with locations' do
          resultant_package_location_qty = packages_location.quantity - quantity_to_move
          resultant_package_location_2_qty = packages_location_2.quantity - quantity_to_move
          package_qty_changes = [{"packages_location_id" => packages_location.id, "package_id" => @package.id,
            "new_qty" => quantity_to_move}, {"packages_location_id" => packages_location_2.id,
            "package_id" => @package.id, "new_qty" => quantity_to_move}]
          subject.move_partial_quantity(location.id, package_qty_changes, quantity_to_move)
          expect(packages_location.reload.quantity).to eq resultant_package_location_qty
          expect(packages_location_2.reload.quantity).to eq resultant_package_location_2_qty
        end

        it 'do not creates new packages_location record and updates existing with total qty' do
          total_qty        = 10
          package_qty_changes = [{packages_location_id: packages_location.id, package_id: @package.id,
            new_qty: quantity_to_move}, {packages_location_id: packages_location_2.id,
            package_id: @package.id, new_qty: quantity_to_move}]
          expect{
            subject.move_partial_quantity(location.id, package_qty_changes, total_qty)
          }.to change(PackagesLocation, :count).by(1)
          expect(@package.packages_locations.reload.last.quantity).to eq total_qty
        end
      end
    end

    describe '#create_associated_packages_location' do
      let(:location) { create :location }

      it 'creates associated package location record for package' do
        expect{
          subject.create_associated_packages_location(location.id, 2)
        }.to change(PackagesLocation, :count).by(1)
      end
    end

    describe '#create_or_update_location_for_dispatch_from_stockit' do
      let(:order) { create :order }
      let(:orders_package) { create :orders_package, state: 'dispatched', package: @package, order: order }
      let(:dispatched_location) { create :location, :dispatched }

      it 'updates orders_package_id against packages_location record if dispatched' do
        packages_location = create :packages_location, package: @package, location: dispatched_location
        subject.create_or_update_location_for_dispatch_from_stockit(dispatched_location, orders_package.id, orders_package.quantity)
        expect(packages_location.reload.reference_to_orders_package).to eq orders_package.id
      end

      it 'creates new packages_location record with orders_package_id if packages_location record do not exist and package dispatched' do
        expect{
          subject.create_or_update_location_for_dispatch_from_stockit(dispatched_location, orders_package.id, orders_package.quantity)
        }.to change(PackagesLocation, :count).by(1)
        expect(@package.reload.packages_locations.first.reference_to_orders_package).to eq orders_package.id
      end
    end

    describe '#create_dispatched_packages_location_from_gc' do
      let(:dispatched_location) { create :location, :dispatched }
      let(:order) { create :order }
      let(:orders_package) { create :orders_package, state: 'dispatched', package: @package, order: order }
      let(:dispatched_location) { create :location, :dispatched }

      it 'creates dispatched packages location record against package if do not exist' do
        expect{
          subject.create_dispatched_packages_location_from_gc(dispatched_location, orders_package.id, 1)
        }.to change(PackagesLocation, :count).by(1)
        first_location = @package.reload.packages_locations.first
        expect(first_location.location).to eq dispatched_location
        expect(first_location.reference_to_orders_package).to eq orders_package.id
        expect(first_location.quantity).to eq 1
      end

      it 'do not creates dispatched packages_location record if already exists' do
        packages_location = create :packages_location, package: @package, location: dispatched_location,
          reference_to_orders_package: orders_package.id
        expect{
          subject.create_dispatched_packages_location_from_gc(dispatched_location, orders_package.id, 1)
        }.to change(PackagesLocation, :count).by(0)
      end
    end

  end
 end
end
