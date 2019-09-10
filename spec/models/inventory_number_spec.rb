require 'rails_helper'

RSpec.describe InventoryNumber, type: :model do

  let(:inventory_number) { InventoryNumber.new }

  context "validations" do
    it { is_expected.to validate_presence_of(:code) }
    it { is_expected.to validate_uniqueness_of(:code) }
  end

  context "create_with_next_code" do
    it "assigns next inventory code during create" do
      InventoryNumber.create_with_next_code!
      expect(InventoryNumber.first.code).to_not be_nil
    end

    it "assigns count of inventory code during create" do
      InventoryNumber.create(code: "000001")
      InventoryNumber.create(code: "000002")
      InventoryNumber.create(code: "000003")
      InventoryNumber.create_with_next_code!
      expect(InventoryNumber.last.code).to eql("000004")
    end
  end

  context "max_code" do
    it "returns highest code in table" do
      InventoryNumber.create_with_next_code!
      InventoryNumber.first.update_column(:code, "123")
      expect(InventoryNumber.max_code).to eql(123)
    end
    it "returns 0 when table is empty" do
      expect(InventoryNumber.max_code).to eql(0)
    end
  end

  context "missing_code" do
    it "locates missing entry" do
      InventoryNumber.create(code: "000001")
      InventoryNumber.create(code: "000003")
      expect(InventoryNumber.missing_code).to eql(2)
    end
    it "returns 0 if empty table" do
      expect(InventoryNumber.missing_code).to eql(0)
    end

    it "missing in inventory numbers table but exists in the packages table" do
      InventoryNumber.create(code: "000001")
      create(:package, inventory_number: "000001")
      create(:package, inventory_number: "000002")
      expect(InventoryNumber.missing_code).to eql(3)
    end

  end

end
