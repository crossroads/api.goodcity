module Goodcity
  class DetailFactory
    PERMITTED_DETAIL_TYPES = %w[Computer Electrical ComputerAccessory].freeze
    FIXED_DETAIL_ATTRIBUTES = %w[comp_test_status test_status frequency voltage].freeze

    attr_accessor :item, :package, :stockit_detail_id

    def initialize(item, package)
      @item = item
      @package = package
      @stockit_detail_id = item["detail_id"]
    end

    def run
      package && import_and_save_detail? && package_updated?
    end

    private

    def package_updated?
      package.update_columns(detail_id: detail_id, detail_type: detail_type)
    end

    def import_and_save_detail?
      item["id"] && item["detail_type"] && stockit_detail_id
    end

    def detail_type
      item["detail_type"] || package&.package_type&.subform.titleize
    end

    def detail_id
      return unless PERMITTED_DETAIL_TYPES.include?(item["detail_type"])
      create_detail_record&.id
    end

    def create_detail_record
      GoodcitySync.request_from_stockit = true
      detail_type.classify.constantize.where(stockit_id: stockit_detail_id)
      .first_or_create(send "#{detail_type.underscore}_attributes".to_sym)
    end

    def computer_attributes
      attr_hash = {}
      %w[brand comp_voltage country_id cpu hdd
        lan mar_ms_office_serial_num mar_os_serial_num model
        ms_office_serial_num optical os os_serial_num ram serial_num
        size sound usb video wireless].each do |attr|
        attr_hash.merge({ "#{attr}": item["#{attr}"] })
      end
      attr_hash["stockit_id"] = stockit_detail_id
      attr_hash.merge(lookup_hash)
    end

    def electrical_attributes
      attr_hash = {}
      %w[brand country_id model power serial_number standard
        system_or_region].each do |attr|
        attr_hash.merge({ "#{attr}": item["#{attr}"] })
      end
      attr_hash["stockit_id"] = stockit_detail_id
      attr_hash.merge(lookup_hash)
    end

    def computer_accessory_attributes
      attr_hash = {}
      %w[brand comp_voltage country_id interface
        model serial_num size].each do |attr|
        attr_hash.merge({ "#{attr}": item["#{attr}"] })
      end
      attr_hash["stockit_id"] = stockit_detail_id
      attr_hash.merge(lookup_hash)
    end

    def lookup_hash
      FIXED_DETAIL_ATTRIBUTES.each_with_object({}) do |attr, hash|
        if (key = item[attr].presence)
          name = "electrical_#{attr}" unless (attr == "comp_test_status")
          hash["#{attr}_id"] = Lookup.find_by(name: name, key: key)&.id
        end
      end
    end
  end
end
