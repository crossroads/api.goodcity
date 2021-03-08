require "rails_helper"

describe ManageLocation do

  let(:location) { create :location }
  let(:target_location) { create :location }
  let(:manage_location) { ManageLocation.new(location.id) }

  context "initialization" do
    it { expect(manage_location.instance_variable_get("@location")).to eq(location) }
  end

  context "empty_location?" do
    it "should return true when there is no associated data" do
      expect(manage_location.empty_location?).to eq(true)
    end

    it "should return false when it has package-locations" do
      create :packages_location, location: location

      expect(manage_location.empty_location?).to eq(false)
    end

    it "should return false when it has package-types" do
      package_type = create :package_type
      package_type.location = location
      package_type.save

      expect(manage_location.empty_location?).to eq(false)
    end

    it "should return false when package-invenotry refers same location" do
      create :packages_inventory, location: location
      expect(manage_location.empty_location?).to eq(false)
    end

    it "should return false when printers refers same location" do
      create :printer, location: location
      expect(manage_location.empty_location?).to eq(false)
    end

    it "should return false when printers refers same location" do
      create :stocktake, location: location
      expect(manage_location.empty_location?).to eq(false)
    end
  end

  context "merge_location" do

    it "should merge printers" do
      printer = create :printer, location: location
      ManageLocation.merge_location(location, target_location)

      expect(printer.reload.location).to eq(target_location)
    end

    it "should merge stocktakes" do
      stocktake = create :stocktake, location: location
      ManageLocation.merge_location(location, target_location)

      expect(stocktake.reload.location).to eq(target_location)
    end

    it "should merge packages_inventorys" do
      packages_inventory = create :packages_inventory, location: location
      ManageLocation.merge_location(location, target_location)

      expect(packages_inventory.reload.location).to eq(target_location)
    end

    it "should merge packages_locations" do
      packages_location = create :packages_location, location: location
      ManageLocation.merge_location(location, target_location)

      expect(packages_location.reload.location).to eq(target_location)
    end

    it "should merge package_type" do
      package_type = create :package_type
      package_type.location = location
      package_type.save

      ManageLocation.merge_location(location, target_location)

      expect(package_type.reload.location).to eq(target_location)
    end

    it "should merge packages" do
      package = create :package, location_id: location.id
      ManageLocation.merge_location(location, target_location)

      expect(package.reload.location_id).to eq(target_location.id)
    end
  end
end
