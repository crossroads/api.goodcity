require 'rails_helper'

context StockOperations do
  let(:location1) { create(:location, building: 61) }
  let(:location2) { create(:location, building: 52) }
  let(:subject) {
    Class.new { include StockOperations }
  }

  describe 'Inventorizing a package' do
    let(:package) { create(:package, received_quantity: 21) }

    def inventorize
      subject::Operations::inventorize(package, location1);
    end

    def register_loss
      create(:packages_inventory, package: package, location: location1, quantity: -1, action: 'loss')
    end

    def uninventorize
      subject::Operations::uninventorize(package);
    end

    def package_quantity
      PackagesInventory::Computer.package_quantity(package)
    end

    it 'appends an inventory action' do
      expect { inventorize }.to change {
        PackagesInventory.where(package: package).count
      }.from(0).to(1)

      last_action = PackagesInventory.last
      expect(last_action.action).to eq('inventory')
      expect(last_action.quantity).to eq(21)
    end

    it 'updates the quantity' do
      expect { inventorize }.to change { package_quantity }.from(0).to(21)
    end

    it 'fails to inventorize an already inventorized package' do
      expect { inventorize }.to change(PackagesInventory, :count).by(1)
      expect { inventorize }.to raise_error(Goodcity::AlreadyInventorizedError).with_message('Package already inventorized')
    end

    it 'allows to uninventorize a package which has just been inventorized' do
      expect { inventorize }.to change { package_quantity }.by(21)
      expect { uninventorize }.to change { package_quantity }.by(-21)

      last_action = PackagesInventory.last
      expect(last_action.action).to eq('uninventory')
      expect(last_action.quantity).to eq(-21)
    end

    it 'fails to uninventorize a package if it is not done immediatly after the inventory action' do
      expect { inventorize }.to change { package_quantity }.by(21)
      expect { register_loss }.to change { package_quantity }.by(-1)
      expect { uninventorize }.to raise_error(Goodcity::UninventoryError).with_message('Package cannot be uninventorized')
    end

    it 'allows to re-inventorize a package which has been uninventorized' do
      expect { inventorize }.to change { package_quantity }.by(21)
      expect { uninventorize }.to change { package_quantity }.by(-21)
      expect { inventorize }.to change { package_quantity }.by(21)

      expect(package_quantity).to eq(21)
    end
  end

  describe 'Marking packages as lost/missing' do
    let(:package) { create(:package) }

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

  describe 'Adding/removing items from box and pallets' do
    let!(:setting) { create(:goodcity_setting, key: "stock.enable_box_pallet_creation", value: "true") }
    let(:box_storage_type) { create(:storage_type, :with_box) }
    let(:pallet_storage_type) { create(:storage_type, :with_box) }
    let(:box) { create(:package, :package_with_locations, storage_type: box_storage_type) }
    let(:pallet) { create(:package, :package_with_locations, storage_type: pallet_storage_type) }
    let(:packages) { create_list(:package, 5, :package_with_locations) }
    let(:user) {create :user, :supervisor}
    let(:subject) {
      Class.new { include StockOperations }
    }

    def pack_or_unpack(params)
      subject::Operations::pack_or_unpack(params, user.id)
    end

    context "adding items to box and pallets" do
      it "creates a packages_inventory record to register loss due to packing in a box" do
        params = {
          item_id: packages.sample.id,
          task: "pack",
          id: box.id
        }
        response = pack_or_unpack(params)
        expect(response[:success]).to eq(true)
        expect(response[:packages_inventory].source).to eq(box)
      end

      it "raises an exception if action is not allowed" do
        params = {
          item_id: packages.sample.id,
          task: "not_allowed_task",
          id: box.id
        }
        expect { pack_or_unpack(params) }.to raise_error(
          "Action you are trying to perform is not allowed"
        )
      end
    end

    context "removing items from box and pallets" do
      it "creates a packages_inventory record to register gain due to unpacking item from a box" do
        params = {
          item_id: packages.sample.id,
          task: "unpack",
          id: pallet.id
        }
        response = pack_or_unpack(params)
        expect(response[:success]).to eq(true)
        expect(response[:packages_inventory].source).to eq(pallet)
      end

      it "raises an exception if action is not allowed" do
        params = {
          item_id: packages.sample.id,
          task: "not_allowed_task",
          id: pallet.id
        }
        expect { pack_or_unpack(params) }.to raise_error(
          "Action you are trying to perform is not allowed"
        )
      end
    end
  end
end
