PERMITTED_DETAIL_TYPES = %w[computer electrical computer_accessory].freeze
FIXED_DETAIL_ATTRIBUTES = %w[comp_test_status test_status frequency voltage].freeze

#import data from stockit for item detail and save it in package.
namespace :stockit do
  desc 'Load all item detail records from Stockit'
  task add_stockit_item_details_to_packages: :environment do
    offset = 0
    per_page = 1000

    loop do
      items_json = Stockit::ItemSync.new(nil, offset, per_page).index_with_detail
      offset += per_page
      stockit_items = JSON.parse(items_json["items"])
      bar = RakeProgressbar.new(stockit_items.size)
      break if stockit_items.blank?

      stockit_items.each do |item|
        bar.inc
        package = Package.find_by(stockit_id: item["id"]) if item["id"]
        TaskMethods.new(item, package).run
      end
    end
    bar.finished
  end
end

class TaskMethods
  attr_accessor :item, :package

  def initialize(item, package)
    @item = item
    @package = package
  end

  def run
    if package && import_and_save_detail? && update_package_detail?
      package&.update_columns(
        detail_id: detail_id,
        detail_type: detail_type,
      )
    end
  end

  def import_and_save_detail?
    item["id"] && item["detail_type"] && item["detail_id"]
  end

  def create_new_record?
    item["detail_id"].nil? || item["detail_id"].blank?
  end

  def create_detail_with_attributes
    case detail_type
    when "computer"
      Computer.create(computer_attributes)
    when "electrical"
      Electrical.create(electrical_attributes)
    when "computer_accessory"
      ComputerAccessory.create(computer_accessory_attributes)
    end
  end

  def create_empty_record
    detail_type.classify&.constantize.create unless detail_type.blank?
  end

  def detail_type
    item["detail_type"] || package.package_type&.subform
  end

  def detail_id
    return unless PERMITTED_DETAIL_TYPES.include?(item["detail_type"])

    create_new_record? ? create_empty_record&.id : create_detail_with_attributes&.id
  end

  def computer_attributes
    attr_hash = {}
    %w[brand comp_voltage country_id cpu hdd
      lan mar_ms_office_serial_num mar_os_serial_num model
      ms_office_serial_num optical os os_serial_num ram serial_num
      size sound usb video wireless].each do |attr|
      attr_hash.merge({ "#{attr}": item["#{attr}"] })
    end
    attr_hash.merge(lookup_hash)
  end

  def electrical_attributes
    attr_hash = {}
    %w[brand country_id model power serial_number standard
      system_or_region].each do |attr|
      attr_hash.merge({ "#{attr}": item["#{attr}"] })
    end
    attr_hash.merge(lookup_hash)
  end

  def computer_accessory_attributes
    attr_hash = {}
    %w[brand comp_voltage country_id interface
      model serial_num size].each do |attr|
      attr_hash.merge({ "#{attr}": item["#{attr}"] })
    end
    attr_hash.merge(lookup_hash)
  end

  def lookup_hash
    FIXED_DETAIL_ATTRIBUTES.each_with_object({}) do |item, hash|
      if (key = detail_params[item].presence)
        name = "electrical_#{item}" unless (item == "comp_test_status")
        hash["#{item}_id"] = Lookup.find_by(name: name, key: key)&.id
      end
    end
  end

  def update_package_detail?
    detail_id && detail_type
  end
end

