require "rails_helper"

describe RequestedPackage, :type => :model do

  let(:designation_sync) { double "designation_sync", { create: nil, update: nil } }
  let(:orders_packages_sync) { double "orders_packages_sync", { create: nil, update: nil } }

  before do
    User.current_user = create(:user)
    allow(Stockit::OrdersPackageSync).to receive(:new).and_return(orders_packages_sync)
    allow(Stockit::DesignationSync).to receive(:new).and_return(designation_sync)
  end

  describe "Database columns" do
    it { is_expected.to have_db_column(:user_id).of_type(:integer) }
    it { is_expected.to have_db_column(:package_id).of_type(:integer) }
    it { is_expected.to have_db_column(:quantity).of_type(:integer) }
    it { is_expected.to have_db_column(:is_available).of_type(:boolean) }
  end

  describe "Associations" do
    it { is_expected.to belong_to :user }
    it { is_expected.to belong_to :package }

    it 'is deleted with the user' do
      user = create(:user, :with_requested_packages)
      expect(user.requested_packages.length).to eq(1)
      expect { user.destroy }.to change { RequestedPackage.count }.by(-1)
    end

    it 'it deleted with the package' do
      package = create(:package, :in_user_cart)
      expect(package.requested_packages.length).to eq(1)
      expect { package.destroy }.to change { RequestedPackage.count }.by(-1)
    end
  end

  describe "Unicity" do
    let(:package1) { create(:package) }
    let(:package2) { create(:package) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    it "doesn't allow adding the same package to a user's cart twice" do
      expect {
        create(:requested_package, user: user1, package: package1)
        create(:requested_package, user: user1, package: package2)
        create(:requested_package, user: user2, package: package1)
      }.to_not raise_error
      expect {
        create(:requested_package, user: user1, package: package1)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "Availability" do
    let(:package1) { create(:package) }
    let(:package2) { create(:package) }
    let(:user) { create(:user) }
    let!(:dispatch_location) { create(:location, :dispatched) }
    let(:order) { create(:order, :with_state_awaiting_dispatch) }

    let(:undesignated_package_unpublished) { create(:package, :unpublished) }
    let(:undesignated_package_published) { create(:package, :published) }
    let(:undesignated_package_published_qty_0) { create(:package, :published) }
    let(:designated_orders_package) {
      create(:orders_package, :with_state_designated, quantity: 1, package: create(:package, :published, received_quantity: 1), order: order)
    }
    let(:undesignated_orders_package) {
      create(:orders_package, :with_state_requested, quantity: 1, package: create(:package, :published, received_quantity: 1), order: order)
    }
    let(:dispatched_orders_package) {
      create(:orders_package, :with_state_dispatched, quantity: 1, package: create(:package, :published, received_quantity: 1), order: order)
    }

    before do
      initialize_inventory(
        undesignated_package_unpublished,
        undesignated_package_published,
        [designated_orders_package, undesignated_orders_package, dispatched_orders_package].map(&:package)
      )
    end

    it "marks cart item as available when the package is published" do
      requested_package = create(:requested_package, package: undesignated_package_unpublished)
      expect(requested_package.is_available).to eq(false)
      Package.find(requested_package.package_id).publish
      expect(requested_package.reload.is_available).to eq(true)
    end

    it "marks cart item as unavailable when the package is unpublished" do
      requested_package = create(:requested_package, package: undesignated_package_published)
      expect(requested_package.is_available).to eq(true)
      Package.find(requested_package.package_id).unpublish
      expect(requested_package.reload.is_available).to eq(false)
    end

    it "marks cart item as unavailable when the package has 0 quantity" do
      requested_package = create(:requested_package, package: undesignated_package_published)
      expect(requested_package.is_available).to eq(true)
      package = requested_package.package.reload
      PackagesInventory.append_loss(package: package, quantity: - package.received_quantity, location: package.locations.first)
      expect(requested_package.reload.is_available).to eq(false)
    end

    it "marks cart item as available when the package's quantity is increased > 0" do
      expect(PackagesInventory::Computer.package_quantity(undesignated_package_published_qty_0)).to eq(0)
      requested_package = create(:requested_package, package: undesignated_package_published_qty_0)
      expect(requested_package.is_available).to eq(false)
      package = requested_package.package.reload
      PackagesInventory.append_gain(package_id: package.id, quantity: 1, location: create(:location))
      expect(requested_package.reload.is_available).to eq(true)
    end

    it "marks cart item as available if the package is undesignated" do
      pkg = designated_orders_package.package
      requested_package = create(:requested_package, package: pkg)
      expect(requested_package.is_available).to eq(false)
      designated_orders_package.reload.cancel!
      expect(requested_package.reload.is_available).to eq(true)
    end

    it "marks cart item as unavailable if the package gets designated" do
      pkg = undesignated_orders_package.package
      requested_package = create(:requested_package, package: pkg)
      expect(requested_package.is_available).to eq(true)
      undesignated_orders_package.reload.designate!
      expect(requested_package.reload.is_available).to eq(false)
    end

    it "cart item is marked as unavailable if the package is dispatched" do
      pkg = dispatched_orders_package.package
      requested_package = create(:requested_package, package: pkg)
      expect(pkg.allow_web_publish).to eq(true)
      expect(PackagesInventory::Computer.available_quantity_of(pkg)).to eq(0)
      expect(requested_package.is_available).to eq(false)
    end

    it "cart item is still marked as unavailable after a designated package gets dispatched" do
      expect(Stockit::ItemSync).to receive(:dispatch).once
      pkg = designated_orders_package.package
      requested_package = create(:requested_package, package: pkg)
      expect(requested_package.is_available).to eq(false)
      OrdersPackage::Operations.dispatch(designated_orders_package, quantity: designated_orders_package.quantity, from_location: pkg.locations.first)
      expect(requested_package.reload.is_available).to eq(false)
    end
  end

  describe "Live updates" do
    let(:push_service) { PushService.new }
    let(:user) { create(:user, :charity) }

    before(:each) do
      allow(PushService).to receive(:new).and_return(push_service)
    end

    def validate_channels
      expect(push_service).to receive(:send_update_store) do |channels, data|
        expect(channels.flatten).to eq([
          Channel.private_channels_for(charity_user, BROWSE_APP),
          Channel::ORDER_FULFILMENT_CHANNEL
        ].flatten)
        yield(channels, data) if block_given?
      end
    end

    context "When creating a requested_package" do
      let(:pkg) { create(:package, :published) }

      before { initialize_inventory pkg }

      it "Sends changes to the user's browse channel" do
        expect(push_service).to receive(:send_update_store) do |channels, data|
          expect(channels.length).to eq(1)
          expect(channels[0]).to eq(Channel.private_channels_for(user, BROWSE_APP)[0])
          record = data.as_json['item'][:requested_package]
          expect(record[:user_id]).to eq(user.id)
          expect(record[:package_id]).to eq(pkg.id)
          expect(record[:is_available]).to eq(true)
        end
        create(:requested_package, user: user, package: pkg)
      end
    end

    context "When a cart item is updated" do
      let(:pkg) { create(:package, :published) }
      let(:requested_package) { create(:requested_package, user: user, package: pkg) }

      before do
        initialize_inventory pkg
        touch requested_package
      end

      it "Sends changes to the user's browse channel" do
        expect(push_service).to receive(:send_update_store).twice do |channels, data|
          next if data.as_json['item'][:package].present?
          expect(data[:operation]).to eq(:update)
          expect(channels.length).to eq(1)
          expect(channels[0]).to eq(Channel.private_channels_for(user, BROWSE_APP)[0])
          record = data.as_json['item'][:requested_package]
          expect(record[:id]).to eq(requested_package.id)
          expect(record[:is_available]).to eq(false)
        end
        pkg.reload.update(allow_web_publish: false)
      end
    end

    context "When deleting a cart item" do
      let(:pkg) { create(:package, :published) }
      let(:requested_package) { create(:requested_package, user: user, package: pkg) }

      before do
        initialize_inventory pkg
        touch requested_package
      end

      it "Sends changes to the user's browse channel" do
        expect(push_service).to receive(:send_update_store) do |channels, data|
          expect(data[:operation]).to eq(:delete)
          expect(channels.length).to eq(1)
          expect(channels[0]).to eq(Channel.private_channels_for(user, BROWSE_APP)[0])
          expect(data.as_json['item'][:requested_package][:id]).to eq(requested_package.id)
        end
        requested_package.destroy
      end
    end
  end
end
