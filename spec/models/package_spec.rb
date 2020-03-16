require 'rails_helper'
require "rspec/mocks/standalone"

RSpec.describe Package, type: :model do

  before do
    User.current_user = create(:user)
    create(:location, :dispatched)
  end

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
    it{ is_expected.to have_db_column(:weight).of_type(:integer)}
    it{ is_expected.to have_db_column(:pieces).of_type(:integer)}
    it{ is_expected.to have_db_column(:notes).of_type(:text)}
    it{ is_expected.to have_db_column(:state).of_type(:string)}
    it{ is_expected.to have_db_column(:received_at).of_type(:datetime)}
    it{ is_expected.to have_db_column(:rejected_at).of_type(:datetime)}
    it{ is_expected.to have_db_column(:designation_name).of_type(:string)}
    it{ is_expected.to have_db_column(:grade).of_type(:string)}
    it{ is_expected.to have_db_column(:donor_condition_id).of_type(:integer)}
    it{ is_expected.to have_db_column(:saleable).of_type(:boolean)}
    it{ is_expected.to have_db_column(:received_quantity).of_type(:integer)}
    it{ is_expected.to have_db_column(:available_quantity).of_type(:integer)}
    it{ is_expected.to have_db_column(:on_hand_quantity).of_type(:integer)}
    it{ is_expected.to have_db_column(:designated_quantity).of_type(:integer)}
    it{ is_expected.to have_db_column(:dispatched_quantity).of_type(:integer)}

    it{ is_expected.not_to have_db_column(:quantity).of_type(:integer)}
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:package_type_id) }
    it { is_expected.to_not allow_value(-1).for(:on_hand_quantity) }
    it { is_expected.to_not allow_value(-1).for(:available_quantity) }
    it { is_expected.to_not allow_value(-1).for(:designated_quantity) }
    it { is_expected.to_not allow_value(-1).for(:dispatched_quantity) }
    it { is_expected.to_not allow_value(-1).for(:received_quantity) }
    it { is_expected.to_not allow_value(0).for(:received_quantity) }
    it { is_expected.to_not allow_value(0).for(:weight) }
    it { is_expected.to_not allow_value(0).for(:pieces) }
    it do
      [:width, :height, :length, :weight, :pieces].each do |attribute|
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
      let(:package) { create :package, :received, allow_web_publish: true }
      it "should set received_at value" do
        expect(Stockit::ItemSync).to receive(:delete).with(package.inventory_number)
        expect{
          package.mark_missing
        }.to change(package, :received_at).to(nil)
        expect(package.allow_web_publish).to eq(false)
        expect(package.state).to eq("missing")
      end
    end
  end

  describe "unpublish" do
    it "should set allow_web_publish=false" do
      @package = create :package, allow_web_publish: true
      @package.unpublish
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

    it "allows multi quantity stockit sync if package received from admin with inventory_number" do
      package = build :package, :received, request_from_admin: true
      expect(Stockit::ItemSync).to receive(:create).with(package).and_return({"status"=>201, "item_id"=> 12})
      package.add_to_stockit
      expect(package.stockit_id).to eq(12)
    end

    it "do not allows multi quantity stockit sync if package is not received from admin" do
      package = build :package, :received, stockit_id: nil, request_from_admin: false
      expect(Stockit::ItemSync).to receive(:create).with(package).and_return({})
      package.add_to_stockit
      expect(package.stockit_id).to be_nil
    end

    it "should not allow to send sync request to stockit if the detail is invalid" do
      detail = build :computer, {os_serial_num: nil, mar_os_serial_num: "xyz"}
      package = build :package, :received
      package.detail = detail
      expect(Stockit::ItemSync).to_not receive(:create)
      package.save
      package.add_to_stockit
      expect(package.errors).to include(:"detail.mar_os_serial_num")
    end

    it "should not allow to send sync request to stockit if it is a box or pallet" do
      storage_type = create(:storage_type, :with_box)
      package = build(:package, :received, storage_type_id: storage_type.id)
      expect(Stockit::ItemSync).to_not receive(:create)
      package.add_to_stockit
      package.save
    end

    it "should not allow to send sync request to stockit if it is a pallet" do
      storage_type = create(:storage_type, :with_pallet)
      package = build(:package, :received, storage_type_id: storage_type.id)
      expect(Stockit::ItemSync).to_not receive(:create)
      package.add_to_stockit
      package.save
    end

    it "should allow to send sync request to stockit if it is a package" do
      storage_type = create(:storage_type, :with_pkg)
      package = build(:package, :received, storage_type_id: storage_type.id)
      expect(Stockit::ItemSync).to receive(:create).with(package).and_return({"status" => 201, "item_id" => 12})
      package.add_to_stockit
      package.save
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

  describe "#not_multi_quantity" do
    let!(:single_with_inventory_package) { create :package, :with_inventory_record, received_quantity: 1, inventory_number: "000635" }
    let!(:multiquantity_without_inventory_package) { create :package, :with_inventory_record, received_quantity: 5, inventory_number: "000636" }
    let!(:singlequantity_without_inventory_package) { create :package, received_quantity: 1, inventory_number: "000637" }

    it "do not returns multi quantity packages" do
      expect(Package.not_multi_quantity.count).to eq(2)
    end

    it "returns packages with quantity less or equal to 1 (Designated and Undesignated)" do
      expect(Package.not_multi_quantity.count).to eq(2)
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

  # @TODO: remove
  #
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

  describe '#donor_condition_name' do
    let(:package){ create :package, :with_lightly_used_donor_condition}
    it 'returns name of package donor condition' do
      expect(package.donor_condition_name).to eq package.donor_condition.name_en
    end
  end

  describe "Live updates" do
    let(:push_service) { PushService.new }
    let!(:package) { create :package, received_quantity: 1 }
    let!(:package_with_item) { create :package, received_quantity: 1, item_id: 1 }

    before(:each) do
      allow(PushService).to receive(:new).and_return(push_service)
    end

    it "should call push_changes upon change" do
      expect(package).to receive(:push_changes)
      package.notes = "a note"
      package.save
    end

    it "should send changes to the stock channel" do
      expect(push_service).to receive(:send_update_store) do |channels, data|
        expect(channels.length).to eq(1)
        expect(channels).to eq([ Channel::STOCK_CHANNEL ])
      end
      package.notes = "a note"
      package.save
    end

    it "should send changes to the staff if the package has an item" do
      expect(push_service).to receive(:send_update_store) do |channels, data|
        expect(channels.length).to eq(2)
        expect(channels).to eq([ Channel::STOCK_CHANNEL, Channel::STAFF_CHANNEL ])
      end
      package_with_item.notes = "a note"
      package_with_item.save
    end

    describe 'for an UNPUBLISHED package' do
      let!(:package_unpublished) { create :package, :unpublished, received_quantity: 1  }

      it "should not be sent to the browse app" do
        expect(push_service).to receive(:send_update_store) do |channels, data|
          expect(channels).not_to include(Channel::BROWSE_CHANNEL)
        end
        package_unpublished.notes = "a note"
        package_unpublished.save
      end

      it "should be sent to the browse app if it gets published" do
        expect(push_service).to receive(:send_update_store) do |channels, data|
          expect(channels).to include(Channel::BROWSE_CHANNEL)
        end
        package_unpublished.allow_web_publish = true
        package_unpublished.save
      end
    end

    describe 'for a PUBLISHED package' do
      let!(:package_published) { create :package, :published, received_quantity: 1 }

      it "should be sent to the browse app" do
        expect(push_service).to receive(:send_update_store) do |channels, data|
          expect(channels).to include(Channel::BROWSE_CHANNEL)
        end
        package_published.allow_web_publish = true
        package_published.save
      end

      it "should be sent to the browse app if it gets unpublished" do
        expect(push_service).to receive(:send_update_store) do |channels, data|
          expect(channels).to include(Channel::BROWSE_CHANNEL)
        end
        package_published.allow_web_publish = false
        package_published.save
      end
    end
  end

  describe "box/pallets" do
    let(:user) { create(:user, :supervisor, :with_can_manage_packages_permission) }
    let(:box_storage) { create(:storage_type, :with_box) }
    let(:pallet_storage) { create(:storage_type, :with_pallet) }
    let(:package_storage) { create(:storage_type, :with_pkg) }
    let(:box) { create(:package, :with_inventory_record, :package_with_locations, storage_type: box_storage) }
    let(:pallet) { create(:package, :with_inventory_record, :package_with_locations, storage_type: pallet_storage) }
    let(:package1) { create(:package, :with_inventory_record, :package_with_locations, received_quantity: 50, storage_type: package_storage)}
    let(:package2) { create(:package, :with_inventory_record, :package_with_locations, received_quantity: 40, storage_type: package_storage)}
    let(:location) { Location.create(building: "21", area: "D") }
    let!(:creation_setting) { create(:goodcity_setting, key: "stock.enable_box_pallet_creation", value: "true") }
    let!(:addition_setting) { create(:goodcity_setting, key: "stock.allow_box_pallet_item_addition", value: "true") }

    def pack_or_unpack(params)
      Package::Operations.pack_or_unpack(
        container: Package.find(params[:id]),
        package: Package.find(params[:item_id]),
        quantity: params[:quantity],
        location_id: location.id,
        user_id: user.id,
        task: params[:task]
      )
    end

    before(:each) do
      @params1 = {
        id: box.id,
        item_id: package1.id,
        task: 'pack',
        quantity: 5
      }
      @params2 = {
        id: box.id,
        item_id: package2.id,
        task: 'pack',
        quantity: 2
      }
    end

    describe "#associated_packages" do
      it "fetches all the associated packages with a box" do
        pack_or_unpack(@params1)
        pack_or_unpack(@params2)
        expect(box.associated_packages.length).to eq(2)
      end
    end

    describe "#quantity_in_a_box" do
      it "returns the quantity of an item in the box" do
        pack_or_unpack(@params1)
        pack_or_unpack(@params2)
        expect(package1.quantity_in_a_box(box.id)).to eq(5)
      end
    end

    describe "#total_quantity_in_box" do
      it "returns the total quantity of items in the box" do
        pack_or_unpack(@params1)
        pack_or_unpack(@params2)
        expect(box.total_quantity_in_box).to eq(7)
      end
    end

    describe "#box?" do
      it "returns true if is box" do
        expect(box.box?).to eq(true)
      end

      it "returns false if it is not a box" do
        expect(pallet.box?).to eq(false)
      end
    end
  end

  describe 'Computing quantities' do
    context 'when designating' do
      let(:package) { create :package, :with_inventory_number, received_quantity: 10 }
      let(:order_1) { create :order, :with_state_dispatching }
      let(:order_2) { create :order, :with_state_dispatching }
      let(:location) { create :location }

      before do
        allow(Stockit::OrdersPackageSync).to receive(:create)
        allow(Stockit::OrdersPackageSync).to receive(:update)
        initialize_inventory(package, location: location)
      end

      it 'updates the designated_quantity column' do
        expect {
          create :orders_package, order: order_1, package: package, quantity: 4, state: 'designated'
        }.to change { package.reload.designated_quantity }.from(0).to(4)

        expect {
          create :orders_package, order: order_2, package: package, quantity: 2, state: 'designated'
        }.to change { package.reload.designated_quantity }.from(4).to(6)
      end

      it 'updates the available_quantity column' do
        expect {
          create :orders_package, order: order_1, package: package, quantity: 4, state: 'designated'
        }.to change { package.reload.available_quantity }.from(10).to(6)

        expect {
          create :orders_package, order: order_2, package: package, quantity: 2, state: 'designated'
        }.to change { package.reload.available_quantity }.from(6).to(4)
      end

      it 'doesnt change the dispatched_quantity column' do
        expect {
          create :orders_package, order: order_1, package: package, quantity: 4, state: 'designated'
        }.not_to change { package.reload.dispatched_quantity }
      end

      it 'doesnt change the on_hand_quantity column' do
        expect {
          create :orders_package, order: order_1, package: package, quantity: 4, state: 'designated'
        }.not_to change { package.reload.on_hand_quantity }
      end
    end


    context 'when dispatching' do
      let(:package) { create :package, :with_inventory_number, received_quantity: 10 }
      let(:order_1) { create :order, :with_state_dispatching }
      let(:order_2) { create :order, :with_state_dispatching }
      let(:orders_package_1) { create :orders_package, order: order_1, package: package, quantity: 4, state: 'designated' }
      let(:orders_package_2) { create :orders_package, order: order_2, package: package, quantity: 4, state: 'designated' }
      let(:location) { create :location }

      before do
        allow(Stockit::OrdersPackageSync).to receive(:create)
        allow(Stockit::OrdersPackageSync).to receive(:update)
        initialize_inventory(package, location: location)
        touch(orders_package_1, orders_package_2)
      end

      it 'updates the dispatched_quantity column' do
        expect(package.on_hand_quantity).to eq(10)
        expect {
          OrdersPackage::Operations.dispatch(orders_package_1, quantity: 2, from_location: location)
        }.to change { package.reload.dispatched_quantity }.from(0).to(2)

        expect {
          OrdersPackage::Operations.dispatch(orders_package_2, quantity: 2, from_location: location)
        }.to change { package.reload.dispatched_quantity }.from(2).to(4)
      end

      it 'updates the on_hand_quantity column' do
        expect {
          OrdersPackage::Operations.dispatch(orders_package_1, quantity: 2, from_location: location)
        }.to change { package.reload.on_hand_quantity }.from(10).to(8)

        expect {
          OrdersPackage::Operations.dispatch(orders_package_2, quantity: 2, from_location: location)
        }.to change { package.reload.on_hand_quantity }.from(8).to(6)
      end

      it 'updates the designated_quantity column' do
        expect {
          OrdersPackage::Operations.dispatch(orders_package_1, quantity: 4, from_location: location)
        }.to change { package.reload.designated_quantity }.from(8).to(4)

        expect {
          OrdersPackage::Operations.dispatch(orders_package_2, quantity: 2, from_location: location)
        }.to change { package.reload.designated_quantity }.from(4).to(2)
      end

      it 'does not change the available_quantity column' do
        expect {
          OrdersPackage::Operations.dispatch(orders_package_1, quantity: 4, from_location: location)
        }.not_to change { package.reload.available_quantity }
      end
    end

    context 'when undispatching' do
      let(:package) { create :package, :with_inventory_record, :with_inventory_number, received_quantity: 10 }
      let(:order_1) { create :order, :with_state_dispatching }
      let(:order_2) { create :order, :with_state_dispatching }
      let(:orders_package_1) { create :orders_package, :with_inventory_record, order: order_1, package: package, quantity: 4, state: 'dispatched' }
      let(:orders_package_2) { create :orders_package, :with_inventory_record, order: order_2, package: package, quantity: 4, state: 'dispatched' }
      let(:location) { create :location }

      before do
        allow(Stockit::OrdersPackageSync).to receive(:create)
        allow(Stockit::OrdersPackageSync).to receive(:update)
        touch(orders_package_1, orders_package_2)
      end

      it 'updates the dispatched_quantity column' do
        expect {
          OrdersPackage::Operations.undispatch(orders_package_1, quantity: 4, to_location: location)
        }.to change { package.reload.dispatched_quantity }.from(8).to(4)

        expect {
          OrdersPackage::Operations.undispatch(orders_package_2, quantity: 2, to_location: location)
        }.to change { package.reload.dispatched_quantity }.from(4).to(2)
      end

      it 'updates the on_hand_quantity column' do
        expect {
          OrdersPackage::Operations.undispatch(orders_package_1, quantity: 4, to_location: location)
        }.to change { package.reload.on_hand_quantity }.from(2).to(6)

        expect {
          OrdersPackage::Operations.undispatch(orders_package_2, quantity: 2, to_location: location)
        }.to change { package.reload.on_hand_quantity }.from(6).to(8)
      end

      it 'updates the designated_quantity column' do
        expect {
          OrdersPackage::Operations.undispatch(orders_package_1, quantity: 4, to_location: location)
        }.to change { package.reload.designated_quantity }.from(0).to(4)

        expect {
          OrdersPackage::Operations.undispatch(orders_package_2, quantity: 2, to_location: location)
        }.to change { package.reload.designated_quantity }.from(4).to(6)
      end

      it 'does not change the available_quantity column' do
        expect {
          OrdersPackage::Operations.undispatch(orders_package_1, quantity: 4, to_location: location)
        }.not_to change { package.reload.available_quantity }
      end
    end

    context 'when applying generic inventory quantity changes' do
      let(:original_qty) { 10 }
      let(:package) { create :package, :with_inventory_record, :with_inventory_number, received_quantity: original_qty }
      let(:order_1) { create :order, :with_state_dispatching }
      let(:order_2) { create :order, :with_state_dispatching }
      let(:location) { create :location }

      [
        [ :gain,    3],
        [ :unpack,  3],
        [ :move,    3],
        [ :loss,    -3],
        [ :pack,    -3],
        [ :move,    -3]
      ].each do |test_case|
        action, quantity_change = test_case

        describe "by doing a #{action} action of #{quantity_change}" do

          it 'updates the on_hand_quantity column by #{quantity_change}' do
            expect {
              create :packages_inventory, package: package, action: action, quantity: quantity_change, location: location
            }.to change { package.reload.on_hand_quantity }.from(original_qty).to(original_qty + quantity_change)
          end

          it 'updates the available_quantity column by #{quantity_change}' do
            expect {
              create :packages_inventory, package: package, action: action, quantity: quantity_change, location: location
            }.to change { package.reload.available_quantity }.from(original_qty).to(original_qty + quantity_change)
          end

          it 'doesnt update the dispatched_quantity column' do
            expect {
              create :packages_inventory, package: package, action: action, quantity: quantity_change, location: location
            }.not_to change { package.reload.dispatched_quantity }
          end

          it 'doesnt update the designated_quantity column' do
            expect {
              create :packages_inventory, package: package, action: action, quantity: quantity_change, location: location
            }.not_to change { package.reload.designated_quantity }
          end
        end
      end
    end
  end
end
