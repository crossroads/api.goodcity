require "rails_helper"

describe CartItem, :type => :model do

  let(:designation_sync) { double "designation_sync", { create: nil, update: nil } }
  let(:orders_packages_sync) { double "orders_packages_sync", { create: nil, update: nil } }

  before do
    allow(Stockit::OrdersPackageSync).to receive(:new).and_return(orders_packages_sync)
    allow(Stockit::DesignationSync).to receive(:new).and_return(designation_sync)
  end

  describe "Database columns" do
    it { is_expected.to have_db_column(:user_id).of_type(:integer) }
    it { is_expected.to have_db_column(:package_id).of_type(:integer) }
    it { is_expected.to have_db_column(:is_available).of_type(:boolean) }
  end

  describe "Associations" do
    it { is_expected.to belong_to :user }
    it { is_expected.to belong_to :package }

    it 'is deleted with the user' do
      user = create(:user, :with_cart_items)
      expect(user.cart_items.length).to eq(1)
      expect { user.destroy }.to change { CartItem.count }.by(-1)
    end

    it 'it deleted with the package' do
      package = create(:package, :in_user_cart)
      expect(package.cart_items.length).to eq(1)
      expect { package.destroy }.to change { CartItem.count }.by(-1)
    end
  end

  describe "Unicity" do
    let(:package1) { create(:package) }
    let(:package2) { create(:package) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    it "doesn't allow adding the same package to a user's cart twice" do
      expect {
        create(:cart_item, user: user1, package: package1)
        create(:cart_item, user: user1, package: package2)
        create(:cart_item, user: user2, package: package1)
      }.to_not raise_error
      expect {
        create(:cart_item, user: user1, package: package1)
      }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "Availability" do
    let(:package1) { create(:package) }
    let(:package2) { create(:package) }
    let(:user) { create(:user) }
    let!(:dispatch_location) { create(:location, :dispatched) }

    let(:undesignated_package_unpublished) { create(:package, :unpublished) }
    let(:undesignated_package_published) { create(:package, :published) }
    let(:undesignated_package_published_qty_0) { create(:package, :published, quantity: 0) }
    let(:designated_orders_package) {
      create(:orders_package, :with_state_designated, package: create(:package, :published, quantity: 1))
    }
    let(:undesignated_orders_package) {
      create(:orders_package, :with_state_requested, package: create(:package, :published, quantity: 1))
    }
    let(:dispatched_orders_package) {
      create(:orders_package, :with_state_dispatched, package: create(:package, :published, quantity: 1))
    }


    it "marks cart item as available when the package is published" do
      cart_item = create(:cart_item, package: undesignated_package_unpublished)
      expect(cart_item.is_available).to eq(false)
      Package.find(cart_item.package_id).publish
      expect(cart_item.reload.is_available).to eq(true)
    end

    it "marks cart item as unavailable when the package is unpublished" do
      cart_item = create(:cart_item, package: undesignated_package_published)
      expect(cart_item.is_available).to eq(true)
      Package.find(cart_item.package_id).unpublish
      expect(cart_item.reload.is_available).to eq(false)
    end

    it "marks cart item as unavailable when the package has 0 quantity" do
      cart_item = create(:cart_item, package: undesignated_package_published)
      expect(cart_item.is_available).to eq(true)
      Package.find(cart_item.package_id).update(quantity: 0)
      expect(cart_item.reload.is_available).to eq(false)
    end

    it "marks cart item as available when the package's quantity is increased > 0" do
      cart_item = create(:cart_item, package: undesignated_package_published_qty_0)
      expect(cart_item.is_available).to eq(false)
      Package.find(cart_item.package_id).update(quantity: 1)
      expect(cart_item.reload.is_available).to eq(true)
    end

    it "marks cart item as available if the package is undesignated" do
      pkg = designated_orders_package.package
      cart_item = create(:cart_item, package: pkg)
      expect(cart_item.is_available).to eq(false)
      designated_orders_package.reload.cancel!
      expect(cart_item.reload.is_available).to eq(true)
    end

    it "marks cart item as unavailable if the package gets designated" do
      pkg = undesignated_orders_package.package
      cart_item = create(:cart_item, package: pkg)
      expect(cart_item.is_available).to eq(true)
      undesignated_orders_package.reload.designate!
      expect(cart_item.reload.is_available).to eq(false)
    end

    it "cart item is marked as unavailable if the package is dispatched" do
      pkg = dispatched_orders_package.package
      cart_item = create(:cart_item, package: pkg)
      expect(pkg.allow_web_publish).to eq(true)
      expect(pkg.quantity.positive?).to eq(true)
      expect(cart_item.is_available).to eq(false)
    end

    it "cart item is still marked as unavailable after a designated package gets dispatched" do
      pkg = designated_orders_package.package
      cart_item = create(:cart_item, package: pkg)
      expect(cart_item.is_available).to eq(false)
      designated_orders_package.reload.dispatch!
      expect(cart_item.reload.is_available).to eq(false)
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

    context "When creating a cart_item" do
      let!(:pkg) { create(:package, :published) }

      it "Sends changes to the user's browse channel" do
        expect(push_service).to receive(:send_update_store) do |channels, data|
          expect(channels.length).to eq(1)
          expect(channels[0]).to eq(Channel.private_channels_for(user, BROWSE_APP)[0])
          record = data.as_json['item'][:cart_item]
          expect(record[:user_id]).to eq(user.id)
          expect(record[:package_id]).to eq(pkg.id)
          expect(record[:is_available]).to eq(true)
        end
        create(:cart_item, user: user, package: pkg)
      end
    end

    context "When a cart item is updated" do
      let!(:pkg) { create(:package, :published) }
      let!(:cart_item) { create(:cart_item, user: user, package: pkg) }

      it "Sends changes to the user's browse channel" do
        expect(push_service).to receive(:send_update_store).twice do |channels, data|
          next if data.as_json['item'][:package].present?
          expect(data[:operation]).to eq(:update)
          expect(channels.length).to eq(1)
          expect(channels[0]).to eq(Channel.private_channels_for(user, BROWSE_APP)[0])
          record = data.as_json['item'][:cart_item]
          expect(record[:id]).to eq(cart_item.id)
          expect(record[:is_available]).to eq(false)
        end
        pkg.reload.update(allow_web_publish: false)
      end
    end

    context "When deleting a cart item" do
      let!(:pkg) { create(:package, :published) }
      let!(:cart_item) { create(:cart_item, user: user, package: pkg) }

      it "Sends changes to the user's browse channel" do
        expect(push_service).to receive(:send_update_store) do |channels, data|
          expect(data[:operation]).to eq(:delete)
          expect(channels.length).to eq(1)
          expect(channels[0]).to eq(Channel.private_channels_for(user, BROWSE_APP)[0])
          expect(data.as_json['item'][:cart_item][:id]).to eq(cart_item.id)
        end
        cart_item.destroy
      end
    end
  end
end
