require "rails_helper"
require "goodcity/detail_factory"

describe Goodcity::DetailFactory do
  PACKAGE_DETAIL_TYPES = {
    computer: {
      "stockit_id": "1231",
      "brand": "asus",
      "cpu": "1GhZ",
      "detail_id": "1234",
      "model": "GCW123SAD123",
      "sound": "Dolby Digital",
      "usb": "test123",
      "serial_num": "serialNumber"
    },
    electrical: {
      "stockit_id": "1230",
      "brand": "havells",
      "detail_id": "1239",
      "model": "GCW123SAD1234",
      "serial_num": "serialNumber",
      "power": "power",
    },
    computer_accessory: {
      "stockit_id": "1232",
      "brand": "dell",
      "model": "GCW123SAD1235",
      "detail_id": "12431",
      "serial_num": "serialNumber"
    }
  }

  def stock_item_hash_for(detail_type, pkg_id)
    PACKAGE_DETAIL_TYPES[detail_type.to_sym].merge({"detail_type": detail_type, "package_id": pkg_id})
  end

  context "run" do
    describe "creates a detail record with data and assigns it to package" do
      it "creates computer" do
        package = create(:package, :with_inventory_number, stockit_id: "1231")
        detail_factory = described_class.new(stock_item_hash_for("computer", package.id), package)
        detail_factory.run
        expect(package.detail.present?).to eq(true)
        expect(package.detail.model).to eq("GCW123SAD123")
        expect(package.detail.brand).to eq("asus")
      end

      it "creates electrical" do
        package = create(:package, :with_inventory_number, stockit_id: "1230")
        detail_factory = described_class.new(stock_item_hash_for("electrical", package.id), package)
        detail_factory.run
        expect(package.detail.present?).to eq(true)
        expect(package.detail.model).to eq("GCW123SAD1234")
        expect(package.detail.brand).to eq("havells")
      end

      it "creates computer_accessory" do
        package = create(:package, :with_inventory_number, stockit_id: "1232")
        detail_factory = described_class.new(stock_item_hash_for("computer_accessory", package.id), package)
        detail_factory.run
        expect(package.detail.present?).to eq(true)
        expect(package.detail.model).to eq("GCW123SAD1235")
        expect(package.detail.brand).to eq("dell")
      end
    end

    describe "creates a blank detail record" do
      it "with computer" do
        package = create(:package, :with_inventory_number, stockit_id: 2221)
        detail_factory = described_class.new({detail_type: "computer"}, package)
        detail_factory.run
        expect(package.detail.present?).to eq(true)
        expect(package.detail.model).to eq(nil)
        expect(package.detail.brand).to eq(nil)
      end

      it "with electrical" do
        package = create(:package, :with_inventory_number, stockit_id: 2220)
        detail_factory = described_class.new({detail_type: "electrical"}, package)
        detail_factory.run
        expect(package.detail.present?).to eq(true)
        expect(package.detail.model).to eq(nil)
        expect(package.detail.brand).to eq(nil)
      end

      it "with computer_accessory" do
        package = create(:package, :with_inventory_number, stockit_id: 2223)
        detail_factory = described_class.new({detail_type: "computer_accessory"}, package)
        detail_factory.run
        expect(package.detail.present?).to eq(true)
        expect(package.detail.model).to eq(nil)
        expect(package.detail.brand).to eq(nil)
      end
    end
  end
end
