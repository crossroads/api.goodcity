require 'rails_helper'
require "rspec/mocks/standalone"

RSpec.describe Package, type: :model do

  before { User.current_user = create(:user) }

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
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:package_type_id) }
    it { is_expected.to_not allow_value(-1).for(:quantity) }
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
    let!(:single_with_inventory_package) { create :package, quantity: 1, inventory_number: "000635" }
    let!(:multiquantity_without_inventory_package) { create :package, quantity: 5, inventory_number: "000636" }
    let!(:singlequantity_without_inventory_package) { create :package, quantity: 0, inventory_number: "000637" }

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

  describe "after_update" do
    it "#update_packages_location_quantity" do
      package = create(:package, :received, :package_with_locations)
      new_quantity = 4
      packages_location = package.packages_locations.first
      expect {
        package.update(received_quantity: new_quantity)
        packages_location.reload
      }.to change(packages_location, :quantity).from(package.received_quantity).to(new_quantity)
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

  describe '#create_or_update_orders_package_for_nested_designation_ and_dispatch_from_Stockit' do
    let(:order) { create :order }
    it 'creates new orders_package record for the package and recalculates quantity' do
      package = create :package, order: order, quantity: 100, received_quantity: 100
      expect{
        package.designate_and_undesignate_from_stockit
      }.to change(OrdersPackage, :count).by(1)
      expect(package.quantity).to eq 0
      orders_package = package.reload.orders_packages.first
      expect(orders_package.quantity).to eq(package.received_quantity)
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

  describe '#donor_condition_name' do
    let(:package){ create :package, :with_lightly_used_donor_condition}
    it 'returns name of package donor condition' do
      expect(package.donor_condition_name).to eq package.donor_condition.name_en
    end
  end

  describe "#cancel_designation" do
    let(:package) { create :package }
    let!(:orders_package) { create :orders_package, package: package, state: 'designated', quantity: 1 }

    it 'changes state of first orders_package having state as designated to cancelled' do
      expect{
        package.cancel_designation
      }.to change{orders_package.reload.state}.from('designated').to('cancelled')
    end
  end

  describe "#singleton_and_has_designation?" do
    let(:package) { create :package, received_quantity: 1, quantity: 0 }
    let!(:orders_package) { create :orders_package, package: package, state: 'designated', quantity: 1 }

    it 'check package has designation and received quantity is one or not' do
      expect(package.singleton_and_has_designation?).to be_truthy
    end
  end

  describe "Live updates" do
    let(:push_service) { PushService.new }
    let!(:package) { create :package, received_quantity: 1, quantity: 0 }
    let!(:package_with_item) { create :package, received_quantity: 1, quantity: 0, item_id: 1 }

    before(:each) do
      allow(PushService).to receive(:new).and_return(push_service)
    end

    it "should call push_changes upon change" do
      expect(package).to receive(:push_changes)
      package.quantity = 2
      package.save
    end

    it "should send changes to the stock channel" do
      expect(push_service).to receive(:send_update_store) do |channels, data|
        expect(channels.length).to eq(1)
        expect(channels).to eq([ Channel::STOCK_CHANNEL ])
      end
      package.quantity = 2
      package.save
    end

    it "should send changes to the staff if the package has an item" do
      expect(push_service).to receive(:send_update_store) do |channels, data|
        expect(channels.length).to eq(2)
        expect(channels).to eq([ Channel::STOCK_CHANNEL, Channel::STAFF_CHANNEL ])
      end
      package_with_item.quantity = 2
      package_with_item.save
    end

    describe 'for an UNPUBLISHED package' do
      let!(:package_unpublished) { create :package, :unpublished, received_quantity: 1, quantity: 0 }

      it "should not be sent to the browse app" do
        expect(push_service).to receive(:send_update_store) do |channels, data|
          expect(channels).not_to include(Channel::BROWSE_CHANNEL)
        end
        package_unpublished.quantity = 2
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
      let!(:package_published) { create :package, :published, received_quantity: 1, quantity: 0 }

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
end
