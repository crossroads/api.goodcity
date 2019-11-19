require 'rails_helper'

context LocationOperations do

  describe 'Moving packages' do
    let(:src_location) { create(:location) }
    let(:dest_location) { create(:location) }
    let(:pkg_loc) { create(:packages_location, location: src_location, quantity: 30) }
    let(:pkg) { pkg_loc.package }
    let(:subject) {
      Class.new { include LocationOperations }
    }

    def move(qty, from: src_location, to: dest_location)
      subject::Operations::move(qty, pkg,
        from: from,
        to: to)
    end

    context 'the destination location already has some packages' do
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

      it 'destroys the source packages_location if it is empty' do
        expect { move(30) }.to change {
          dest_pkg_loc.reload.quantity
        }.by(30)

        expect(dest_pkg_loc.reload.quantity).to eq(32)
        expect(PackagesLocation.find_by(id: pkg_loc.id)).to be_nil
      end
    end

    context 'the destination location is empty' do
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

      it 'destroys the source packages_location if it is emptied' do
        expect(dest_pkg_loc).to be_nil
        move(30)

        expect(dest_pkg_loc.quantity).to eq(30)
        expect(PackagesLocation.find_by(id: pkg_loc.id)).to be_nil
      end
    end

    describe 'Validations' do
      it 'fails to move an invalid quantity (<=0)' do
        expect { move(-1) }.to raise_error(StandardError).with_message('Invalid move quantity (-1)')
      end

      it 'fails to move from a bad location' do
        expect { move(1, from: 0) }.to raise_error(StandardError).with_message("Couldn't find Location with 'id'=0")
      end

      it 'fails to move to a bad location' do
        expect { move(1, to: 0) }.to raise_error(StandardError).with_message("Couldn't find Location with 'id'=0")
      end
    end
  end

end
