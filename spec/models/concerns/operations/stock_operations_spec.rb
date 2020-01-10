require 'rails_helper'

context StockOperations do
  describe 'Marking packages as lost/missing' do
    let(:location1) { create(:location, building: 61) }
    let(:location2) { create(:location, building: 52) }
    let(:package) { create(:package) }
    let(:subject) {
      Class.new { include StockOperations }
    }

    before do
      create(:packages_inventory, :inventory, quantity: 30, package: package, location: location1)
      create(:packages_inventory, :inventory, quantity: 3, package: package, location: location2)
      create(:packages_inventory, :gain, quantity: 3, package: package, location: location1)
    end

    def register_loss(quantity, from_location)
      subject::Operations::register_loss(package,
        quantity: quantity,
        from_location: from_location)
    end

    context 'for a partial quantity of one location' do
      it 'negates the amount from the inventory' do
        expect { register_loss(10, location1) }.to change {
          PackagesInventory::Computer.quantity_where(location: location1, package: package)
        }.from(33).to(23)
      end

      it 'adds a single row the packages_inventory' do
        expect { register_loss(10, location1) }.to change(PackagesInventory, :count).by(1)
      end

      it 'updates the packages_location record' do
        expect { register_loss(10, location1) }.to change {
          PackagesLocation.find_by(package: package, location: location1).quantity
        }.from(33).to(23)
      end

      it 'doesnt affect other locations' do
        expect { register_loss(10, location1) }.not_to change {
          PackagesInventory::Computer.quantity_where(location: location2, package: package)
        }
      end

      context 'with some quantity remaining for designated items' do
        before { create(:orders_package, :with_state_designated, package: package, quantity: 26) } # Location 1+2 have enough to fulfill this order
        # 36 on hand
        # 26 designated
        # 10 available
        it 'succeeds' do
          expect { register_loss(10, location1) }.to change {
            PackagesInventory::Computer.quantity_where(location: location1, package: package)
          }.from(33).to(23)
        end
      end

      context 'breaking the required quantity for designated items' do
        let!(:orders_package) { create(:orders_package, :with_state_designated, package: package, quantity: 27) } # Location 1+2 do not have enough to fulfill this order
        let(:order_code) { orders_package.order.code }
        # 36 on hand
        # 27 designated
        # 9 available
        it 'fails' do
          expect { register_loss(10, location1) }.to raise_error(StandardError).with_message(
            "Will break the quantity required for orders (#{order_code}), please undesignate first"
          )
        end
      end
    end

    context 'for the entire quantity of one location' do
      it 'negates the amount from the inventory' do
        expect { register_loss(33, location1) }.to change {
          PackagesInventory::Computer.quantity_where(location: location1, package: package)
        }.from(33).to(0)
      end

      it 'adds a single row the packages_inventory' do
        expect { register_loss(33, location1) }.to change(PackagesInventory, :count).by(1)
      end

      it 'destroys the packages_location record' do
        expect { register_loss(33, location1) }.to change {
          PackagesLocation.where(package: package, location: location1).count
        }.from(1).to(0)
      end

      it 'doesnt affect other locations' do
        expect { register_loss(33, location1) }.not_to change {
          PackagesInventory::Computer.quantity_where(location: location2, package: package)
        }
      end

      context 'with some quantity remaining for designated items' do
        before { create(:orders_package, package: package, quantity: 3) } # Location 2 has enough to fulfill this order

        it 'suceeds' do
          expect { register_loss(33, location1) }.to change {
            PackagesInventory::Computer.quantity_where(location: location1, package: package)
          }.from(33).to(0)
        end
      end

      context 'breaking the required quantity for designated items' do
        let!(:orders_package) { create(:orders_package, :with_state_designated, package: package, quantity: 6) } # Location 2 does not have enough to fulfill this order
        let(:order_code) { orders_package.order.code }

        it 'fails' do
          expect { register_loss(33, location1) }.to raise_error(StandardError).with_message(
            "Will break the quantity required for orders (#{order_code}), please undesignate first"
          )
        end
      end
    end
  end
end
