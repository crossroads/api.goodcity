#
# Grabs the designations from Stockit and updates GoodCity
#
# DO NOT LOAD THIS SCRIPT IN RUNTIME - it will prevent push notifications
#
# > require 'goodcity/import_designations'
# > ImportDesignations.new.run(['S12345', 'S54321'])

# turn off PushUpdates to prevent broadcasting huge updates
class PushService
  def send_update_store(channels, data)
  end
end

class ImportDesignations

  def initialize(codes)
    @codes = codes
    Order.record_timestamps = false
    ActiveRecord::Base.logger.level = 1 # quieter when run in console
    @log_file_name = 'import_designations.log'
  end

  def run(codes)
    designations_json = Stockit::DesignationSync.new(nil, {code: codes.join(',')}).index
    # designations_json = Stockit::DesignationSync.index
    orders = JSON.parse(designations_json["designations"]) || []
    @bar = RakeProgressbar.new(orders.size)
    @log = File.open(File.join(Rails.root, 'tmp', @log_file_name), 'w')

    count = 0
    orders.each do |order_attrs|
      @bar.inc
      next if order_attrs['detail_type'] == 'GoodCity' # skip these for now
      # break if count > 10
      count += 1
      ActiveRecord::Base.transaction do
        import_order(order_attrs)
        # puts "TEST. Rolling back changes"; raise ActiveRecord::Rollback # don't commit the changes. just test for now
      end
    end

    Order.record_timestamps = true
    @bar.finished
    @log.close
  end


  private

  def import_order(order_attrs)
    raise ImportOrderError if order_attrs['detail_type'] == 'GoodCity' # failsafe

    order = Order.where(stockit_id: order_attrs["id"]).first #_or_initialize

    if (order_attrs["detail_type"] === "LocalOrder") && order_attrs["detail_id"].present?
      order.detail_id = StockitLocalOrder.find_by(stockit_id: order_attrs["detail_id"]).try(:id)
    end

    if order_attrs["activity_id"].present?
      order.stockit_activity_id = StockitActivity.find_by(stockit_id: order_attrs["activity_id"]).try(:id)
    end

    if order_attrs["contact_id"].present?
      order.stockit_contact_id = StockitContact.find_by(stockit_id: order_attrs["contact_id"]).try(:id)
    end

    if order_attrs["organisation_id"].present?
      order.stockit_organisation_id = StockitOrganisation.find_by(stockit_id: order_attrs["organisation_id"]).try(:id)
    end

    if order_attrs["country_id"].present?
      order.country_id = Country.find_by(stockit_id: order_attrs["country_id"]).try(:id)
    end

    order.state = case order_attrs["detail_type"]
                  when "CarryOut", "Shipment"
                    Order::SHIPMENT_STATUS_MAP[order_attrs["status"]]
                  when "LocalOrder"
                    Order::LOCAL_ORDER_STATUS_MAP[order_attrs["status"]]
                  else
                    'draft'
                  end

    order.code = order_attrs["code"]
    order.detail_type = order_attrs["detail_type"]
    order.created_at = order_attrs["created_at"]
    order.updated_at = order_attrs["updated_at"] if order_attrs["updated_at"].present?
    order.people_helped = order_attrs["number_of_people_helped"]
    order.continuous = order_attrs["continuous"]
    order.shipment_date = order_attrs["sent_on"]
    order.staff_note = order_attrs["comments"]
    order.purpose_description = order_attrs["description"]
    order.save!
    log(order.code, "Updated from Stockit")
  end

  def log(code, msg)
    puts("#{code},#{msg}")
    @log.puts("#{code},#{msg}")
  end

  class ImportOrderError < Exception
  end

end