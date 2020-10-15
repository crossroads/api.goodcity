require "rails_helper"
require 'goodcity/import_boxes'

context Goodcity::ImportBoxes do

  subject { described_class.new(user) }

  let(:user) { create :user }
  let(:inventory_number) { '112233' }
  let(:box_storage_type) { create :storage_type, :with_box }
  let(:pallet_storage_type) { create :storage_type, :with_pallet }
  let(:pkg_storage_type) { create :storage_type, :with_pkg }
  let(:computer_package_type) { create :package_type, code: "VXX"}
  let(:box_of_computers_package_type) { create :package_type, code: "VB", allow_box: true }
  let!(:subpackage_type) { create(:subpackage_type, package_type: box_of_computers_package_type, child_package_type: computer_package_type, is_default: false) }
  let(:package) { create :package, :with_inventory_record, package_type: computer_package_type, inventory_number: inventory_number, received_quantity: 10 }
  let(:location) { package.locations.first }
  let(:row) { {
    "inventory_number"  => package.inventory_number,
    "box_number"        => "B000001",
    "description"       => "This is a stockit box",
    "comments"          => "Steve was here",
    "length"            => 10,
    "height"            => 11,
    "width"             => 12,
    "weight"            => 13
  } }

  context "Importing a box" do

    before do
      touch(package, box_storage_type, pallet_storage_type, pkg_storage_type, location)
      expect(Package.count).to eq(1)
      expect(package.locations.count).to eq(1)
    end

    it "creates a new package of Box type" do
      expect { subject.import_row!(row) }.to change(Package, :count).by(1)
      expect(Package.last.storage_type).to eq(box_storage_type)
    end

    it "places the new box in the same location as the package" do
      box = subject.import_row!(row)
      expect(box.locations.count).to eq(1)
      expect(box.locations.first).to eq(location)
    end

    it "packs all the package quantity into the box" do
      box = nil
      expect { box = subject.import_row!(row) }.to change {
        PackagesInventory::Computer.package_quantity(package)
      }.from(10).to(0)

      expect(package.reload.on_hand_quantity).to eq(0)

      inventory_row = PackagesInventory.where(package: package).last
      expect(inventory_row.package_id).to   eq(package.id)
      expect(inventory_row.location_id).to  eq(location.id)
      expect(inventory_row.user_id).to      eq(user.id)
      expect(inventory_row.action).to       eq("pack")
      expect(inventory_row.source_type).to  eq("Package")
      expect(inventory_row.source_id).to    eq(box.id)
      expect(inventory_row.quantity).to     eq(-10)
    end

    it "doesn't create the box it already exists" do
      box = subject.import_row!(row)

      expect {
        expect(subject.import_row!(row)).to eq(box)
      }.not_to change(PackagesInventory, :count)
    end

    it "sets the box's inventory number to the stockit box_number field" do
      box = subject.import_row!(row)
      expect(box.inventory_number).to eq(row['box_number'])
    end

    it "sets the correct size/weight properties" do
      box = subject.import_row!(row)

      expect(box.width).to  eq(row['width'])
      expect(box.height).to eq(row['height'])
      expect(box.length).to eq(row['length'])
      expect(box.weight).to eq(row['weight'])
    end

    it "raises an error if the inventory_number is missing" do
      expect {
        subject.import_row!(row.merge("inventory_number" => ""))
      }.to raise_error(Goodcity::InvalidParamsError).with_message('Missing inventory_number')
    end

    it "raises an error if the box_number is missing" do
      expect {
        subject.import_row!(row.merge("box_number" => ""))
      }.to raise_error(Goodcity::InvalidParamsError).with_message('Missing box_number')
    end

    it "raises an error if the package does not exist in goodcity" do
      expect(Package.find_by(inventory_number: '999999')).to eq(nil)

      expect {
        subject.import_row!(row.merge("inventory_number" => "999999"))
      }.to raise_error(Goodcity::NotFoundError).with_message(
        "Package with inventory number '999999' was not found"
      )
    end

    it "raises an error if the package doesn't have its entire quantity available to be packed in the box" do
      Package::Operations.register_loss(package, quantity: 5, location: location)
      expect(package.reload.on_hand_quantity).to eq(5)
      expect(package.reload.received_quantity).to eq(10)

      expect {
        subject.import_row!(row)
      }.to raise_error(Goodcity::InsufficientQuantityError).with_message(
        "The selected quantity (10) is unavailable"
      )
    end
  end
end
