require "rails_helper"
require "goodcity/detail_factory"

describe Goodcity::DetailFactory do
  PACKAGE_DETAIL_TYPES = {
    computer: {
      "stockit_id": "1231",
      "brand": "Asus",
      "cpu": "1GhZ",
      "model": "GCW123SAD123",
      "sound": "Dolby Digital",
      "usb": "test123",
      "serial_num": "serial number"
    },
    electrical: {
      "stockit_id": "1230",
      "brand": "Asus",
      "model": "GCW123SAD123",
      "serial_num": "serial number",
      "power": "power"
    },
    computer_accessory: {
      "stockit_id": "1232",
      "brand": "Asus",
      "model": "GCW123SAD123",
      "serial_num": "serial number",
    }
  }

  def stock_item_hash_for(detail_type)
    PACKAGE_DETAIL_TYPES[detail_type.to_sym].merge({"detail_type": detail_type})
  end

  describe "run" do
    it "creates a blank detail record and assigns it to package" do
      ["electrical", "computer", "computer_accessory"].each_with_index do |detail_type, index|
        package = create(:package, :with_inventory_number, stockit_id: "123#{index}")
        detail_factory = described_class.new(stock_item_hash_for(detail_type), package)
        detail_factory.run
        expect(@package.detail.present?).to eq(true)
      end
    end

    it "creates a record with data and assigns it to package" do
      ["electrical", "computer", "computer_accessory"].each_with_index do |detail_type, index|
        package = create(:package, :with_inventory_number, stockit_id: "223#{index}")
        detail_factory = described_class.new({}, package)
        detail_factory.run
        expect(@package.detail.present?).to eq(true)
      end
    end
  end
end
