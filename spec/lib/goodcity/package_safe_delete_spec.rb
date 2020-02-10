require 'rails_helper'
require 'goodcity/package_safe_delete'

context Goodcity::PackageSafeDelete do

  subject { described_class.new(inventory_number) }
  let(:inventory_number) { "123245" }
  let(:package) { create(:package, :package_with_locations, :with_images, :in_user_cart, inventory_number: inventory_number) }

  context "initialization" do
    it { expect(subject.instance_variable_get('@inventory_numbers')).to eql([inventory_number]) }
    context "with a list of repetitive inventory_numbers" do
      let(:inventory_number) { ['1', '2', '2', '3']}
      it { expect(subject.instance_variable_get('@inventory_numbers')).to match_array(['1','2','3']) }
    end
  end

  context "run" do
    it "should call ok_to_destroy? and destroy_package" do
      expect(subject).to receive(:ok_to_destroy?).with(package).and_return(true)
      expect(subject).to receive(:destroy_package).with(package)
      subject.run
    end
  end

  context "ok_to_destroy?" do
    context "should return false" do
      let(:package) { create(:package, :with_item, inventory_number: inventory_number) }
      it "when item_id is present" do
        expect(subject.send("ok_to_destroy?", package)).to be false
      end
    end
    it "should return true" do
      expect(subject.send("ok_to_destroy?", package)).to be true
    end
  end

  context "destroy_package" do
    it "should destroy related packages_locations records" do
      expect(package.packages_locations.size).to be > 0
      package.packages_locations.each do |packages_location|
        expect(packages_location).to receive(:destroy)
      end
      subject.send(:destroy_package, package)
    end
    it "should destroy related image records" do
      expect(package.images.size).to be > 0
      package.images.each do |image|
        expect(image).to receive(:destroy)
      end
      subject.send(:destroy_package, package)
    end
    it "should delete related orders_packages records" do
      allow(StockitSyncOrdersPackageJob).to receive(:perform_now) # drop Stockit sync job
      create(:orders_package, package: package)
      expect(package.orders_packages.size).to be > 0
      package.orders_packages.each do |orders_package|
        expect(orders_package).to receive(:delete)
      end
      subject.send(:destroy_package, package)
    end
    it "should destroy related requested_packages records" do
      expect(package.requested_packages.size).to be > 0
      package.requested_packages.each do |requested_package|
        expect(requested_package).to receive(:destroy)
      end
      subject.send(:destroy_package, package)
    end
    it "should call destroy_inventory_number" do
      expect(subject).to receive(:destroy_inventory_number)
      subject.send(:destroy_package, package)
    end
    it "should destroy itself" do
      expect(package).to receive_message_chain([:reload, :destroy])
      subject.send(:destroy_package, package)
    end
  end

  context "destroy_inventory_number" do
    context "with blank inventory_number" do
      let(:inventory_number) { "" }
      it do
        expect(Package.where(inventory_number: inventory_number).size).to eql(0)
        expect(InventoryNumber).to_not receive(:find_by)
        subject.send(:destroy_inventory_number, inventory_number)
      end
    end
    context "with non GC inventory number" do
      let(:inventory_number) { "F54321" }
      it do
        expect(Package.where(inventory_number: inventory_number).size).to eql(0)
        expect(InventoryNumber).to_not receive(:find_by)
        subject.send(:destroy_inventory_number, inventory_number)
      end
    end
    context "with duplicate inventory_number in Packages table" do
      it do
        create(:package, inventory_number: inventory_number)
        create(:package).tap{|p| p.update_column(:inventory_number, inventory_number)}
        expect(Package.where(inventory_number: inventory_number).size).to eql(2)
        expect(InventoryNumber).to_not receive(:find_by)
        subject.send(:destroy_inventory_number, inventory_number)
      end
    end
    it "with valid inventory_number" do
      expect(Package.where(inventory_number: inventory_number).size).to eql(0)
      expect(InventoryNumber).to receive(:find_by)
      subject.send(:destroy_inventory_number, inventory_number)
    end
  end

end
