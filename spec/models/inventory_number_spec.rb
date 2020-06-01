require 'rails_helper'

RSpec.describe InventoryNumber, type: :model do

  let(:inventory_number) { InventoryNumber.new }

  context "validations" do
    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_uniqueness_of(:code) }
  end

  context "create_with_next_code" do
    it "assigns first inventory code during create" do
      expect(InventoryNumber.count).to eql(0)
      expect(Package.count).to eql(0)
      InventoryNumber.create_with_next_code!
      expect(InventoryNumber.count).to eql(1)
      expect(InventoryNumber.first.code).to eql("000001")
    end

    it "assigns next available code during create", shared_connection: true do
      InventoryNumber.create(code: "000001")
      InventoryNumber.create(code: "000002")
      InventoryNumber.create(code: "000003")
      InventoryNumber.create_with_next_code!
      expect(InventoryNumber.last.code).to eql("000004")
    end
  end

  context "next_code" do
    it "picks missing entry in inventory_numbers table" do
      InventoryNumber.create(code: "000001")
      InventoryNumber.create(code: "000003")
      Package.delete_all
      expect(InventoryNumber.next_code).to eql("000002")
    end

    it "picks missing entry in packages table" do
      create(:package, inventory_number: "000001")
      create(:package, inventory_number: "F00002") # should be ignored
      create(:package, inventory_number: "000003")
      InventoryNumber.delete_all
      expect(InventoryNumber.next_code).to eql("000002")
    end

    it "returns 0 if empty table" do
      InventoryNumber.delete_all
      Package.delete_all
      expect(InventoryNumber.next_code).to eql("000001")
    end

    it "no missing entries, picks next one" do
      create(:package, inventory_number: "000001")
      create(:package, inventory_number: "000002")
      create(:package, inventory_number: "000003")
      expect(InventoryNumber.pluck(:code)).to match_array (["000001", "000002", "000003"])
      expect(Package.pluck(:inventory_number)).to match_array(["000001", "000002", "000003"])
      expect(InventoryNumber.next_code).to eql("000004")
    end

  end

  context "max_code" do
    it "returns 0 if no entries" do
      expect(InventoryNumber.count).to eql(0)
      expect(Package.count).to eql(0)
      expect(InventoryNumber.max_code).to eql(0)
    end

    it "returns highest entry from inventory_numbers table" do
      create(:package, inventory_number: "000001")
      create(:package, inventory_number: "000002")
      create(:inventory_number, code: "000003")
      expect(InventoryNumber.max_code).to eql(3)
    end

    it "returns highest number from Packages table" do
      create(:package, inventory_number: "000001")
      create(:package, inventory_number: "000004")
      create(:inventory_number, code: "000003")
      expect(InventoryNumber.max_code).to eql(4)
    end

  end

end
