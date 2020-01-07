require 'rails_helper'

context LocationOperations do

  describe 'Moving packages' do
    let(:dispatch_location) { create(:location, :dispatched) }
    let(:src_location) { create(:location) }
    let(:dest_location) { create(:location) }
    let(:pkg_loc) { create(:packages_location, location: src_location, quantity: 30) }
    let(:pkg) { pkg_loc.package }
    let(:subject) {
      Class.new { include LocationOperations }
    }

    before { touch(pkg) }

    def move(qty, from: src_location, to: dest_location)
      subject::Operations::move(qty, pkg,
        from: from,
        to: to)
    end

    context 'to a destination which already has some packages' do
      let!(:dest_pkg_loc) {
        create :packages_location, package: pkg_loc.package, location: dest_location, quantity: 2
      }

      it 'subtracts the quantity from the source location' do
        expect { move(15) }.to change {
          pkg_loc.reload.quantity
        }.by(-15)
      end

      it 'adds the quantity from the dest location' do
        expect { move(15) }.to change {
          dest_pkg_loc.reload.quantity
        }.by(15)

        expect(dest_pkg_loc.reload.quantity).to eq(17)
      end

      it 'adds a loss row for the source location' do
        expect(PackagesInventory.count).to eq(2)
        expect { move(15) }.to change(PackagesInventory, :count).by(2)

        record = PackagesInventory.last(2).first
        expect(record.location_id).to eq(src_location.id)
        expect(record.action).to eq('loss')
        expect(record.quantity).to eq(-15)
      end


      it 'adds a gain row for the dest location' do
        expect(PackagesInventory.count).to eq(2)
        expect { move(15) }.to change(PackagesInventory, :count).by(2)

        record = PackagesInventory.last
        expect(record.location_id).to eq(dest_location.id)
        expect(record.action).to eq('gain')
        expect(record.quantity).to eq(15)
      end

      it 'negates the quantity in the packages_inventory for the source' do
        expect { move(15) }.to change {
          PackagesInventory::Computer.location_quantity(src_location)
        }.by(-15)
      end

      it 'increments the quantity in the packages_inventory for the destination' do
        expect { move(15) }.to change {
          PackagesInventory::Computer.location_quantity(dest_location)
        }.by(15)
      end

      context 'emptying the source location' do
        it 'destroys the source packages_location if it is empty' do
          expect { move(30) }.to change {
            dest_pkg_loc.reload.quantity
          }.by(30)

          expect(dest_pkg_loc.reload.quantity).to eq(32)
          expect(PackagesLocation.find_by(id: pkg_loc.id)).to be_nil
        end

        it 'negates the quantity in the packages_inventory for the source' do
          expect { move(30) }.to change {
            PackagesInventory::Computer.location_quantity(src_location)
          }.by(-30)
        end
      end
    end

    context 'to an empty destination' do
      def dest_pkg_loc
        PackagesLocation.find_by(location: dest_location, package: pkg)
      end

      it 'subtracts the quantity from the source' do
        expect { move(15) }.to change {
          pkg_loc.reload.quantity
        }.by(-15)
      end

      it 'creates the dest location' do
        expect(dest_pkg_loc).to be_nil
        move(15)
        expect(dest_pkg_loc.quantity).to eq(15)
      end

      it 'negates the quantity in the packages_inventory for the source' do
        expect { move(15) }.to change {
          PackagesInventory::Computer.location_quantity(src_location)
        }.by(-15)
      end

      it 'increments the quantity in the packages_inventory for the destination' do
        expect { move(15) }.to change {
          PackagesInventory::Computer.location_quantity(dest_location)
        }.by(15)
      end

      context 'emptying the source location' do
        it 'destroys the source packages_location' do
          expect(dest_pkg_loc).to be_nil
          move(30)

          expect(dest_pkg_loc.quantity).to eq(30)
          expect(PackagesLocation.find_by(id: pkg_loc.id)).to be_nil
        end

        it 'negates the quantity in the packages_inventory for the source' do
          expect { move(15) }.to change {
            PackagesInventory::Computer.location_quantity(src_location)
          }.by(-15)
        end

        it 'increments the quantity in the packages_inventory for the destination' do
          expect { move(15) }.to change {
            PackagesInventory::Computer.location_quantity(dest_location)
          }.by(15)
        end
      end
    end

    describe 'Validations' do
      it 'fails to move an invalid quantity (<=0)' do
        expect { move(-1) }.to raise_error(Goodcity::BaseError).with_message('Invalid quantity (-1)')
      end

      it 'fails to move from a bad location' do
        expect { move(1, from: 0) }.to raise_error(ActiveRecord::RecordNotFound).with_message("Couldn't find Location with 'id'=0")
      end

      it 'fails to move to a bad location' do
        expect { move(1, to: 0) }.to raise_error(ActiveRecord::RecordNotFound).with_message("Couldn't find Location with 'id'=0")
      end
    end
  end

end
