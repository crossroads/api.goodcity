module Goodcity
  class DetailFactory
    PERMITTED_DETAIL_TYPES = %w[computer electrical computer_accessory].freeze
    FIXED_DETAIL_ATTRIBUTES = %w[comp_test_status test_status frequency voltage].freeze
    REJECT_ATTRIBUTES= %w[detail_type detail_id package_id].freeze
    PACKAGE_DETAIL_ATTRIBUTES = {
      computer_accessory: %w[brand comp_voltage country_id interface
        model serial_num size].freeze,
      computer: %w[brand comp_voltage country_id cpu hdd
        lan mar_ms_office_serial_num mar_os_serial_num model
        ms_office_serial_num optical os os_serial_num ram serial_num
        size sound usb video wireless].freeze,
      electrical: %w[brand country_id model power serial_number standard
        system_or_region].freeze
    }

    attr_accessor :stockit_item_hash, :package, :stockit_detail_id

    def initialize(stockit_item_hash, package)
      @stockit_item_hash = ActiveSupport::HashWithIndifferentAccess.new(stockit_item_hash)
      @package = package
      @stockit_detail_id = @stockit_item_hash["detail_id"]
    end

    def run
      create_detail_and_update_package
    end

    private

    def create_detail_and_update_package
      return false if package.detail.present? # check if records is present on GC
      package && package.update_columns(detail_id: detail_id, detail_type: detail_type)
    end

    def detail_present_on_stockit?
      stockit_item_hash["id"] && stockit_item_hash["detail_type"] && stockit_detail_id
    end

    def detail_type
      stockit_item_hash["detail_type"]&.classify || package.package_type.subform&.classify
    end

    def detail_id
      return unless PERMITTED_DETAIL_TYPES.include?(detail_type.underscore)
      create_detail_record.id
    end

    def create_detail_record
      klass = detail_type.classify.constantize
      # create detail record with data
      if detail_present_on_stockit?
        GoodcitySync.request_from_stockit = true
        klass.where(stockit_id: stockit_detail_id).first_or_create(
          package_detail_attributes(PACKAGE_DETAIL_ATTRIBUTES["#{detail_type.underscore}".to_sym])
        )
      else
        # create empty detail record
        GoodcitySync.request_from_stockit = false
        klass.create({})
      end
    end

    def package_detail_attributes(attributes)
      attr_hash = attributes.each_with_object({}) do |attr, hash|
                    hash["#{attr}"] = stockit_item_hash[attr.to_s]
                  end
      attr_hash["stockit_id"] = stockit_detail_id
      attr_hash.merge(lookup_hash)
      attr_hash.except(*REJECT_ATTRIBUTES)
    end

    def lookup_hash
      FIXED_DETAIL_ATTRIBUTES.each_with_object({}) do |attr, hash|
        if (key = stockit_item_hash[attr].presence)
          name = "electrical_#{attr}" unless (attr == "comp_test_status")
          hash["#{attr}_id"] = Lookup.find_by(name: name, key: key)&.id
        end
      end
    end
  end
end
