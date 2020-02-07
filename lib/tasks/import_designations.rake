
namespace :stockit do
  desc "Load designation details from Stockit"
  task import_designations: :environment do
    designations_json = Stockit::DesignationSync.index
    orders = JSON.parse(designations_json["designations"]) || []

    bar = RakeProgressbar.new(orders.size)
    Order.record_timestamps=false
    orders.each do |value|
      bar.inc
      order = Order.where(stockit_id: value["id"]).first_or_initialize

      if (value["detail_type"] === "LocalOrder") && value["detail_id"].present?
        order.detail_id = StockitLocalOrder.find_by(stockit_id: value["detail_id"]).try(:id)
      end

      if value["activity_id"].present?
        order.stockit_activity_id = StockitActivity.find_by(stockit_id: value["activity_id"]).try(:id)
      end

      if value["contact_id"].present?
        order.stockit_contact_id = StockitContact.find_by(stockit_id: value["contact_id"]).try(:id)
      end

      if value["organisation_id"].present?
        order.stockit_organisation_id = StockitOrganisation.find_by(stockit_id: value["organisation_id"]).try(:id)
      end

      if value["country_id"].present?
        order.country_id = Country.find_by(stockit_id: value["country_id"]).try(:id)
      end

      if ["CarryOut", "Shipment"].include?(value["detail_type"])
        order.state = Order::SHIPMENT_STATUS_MAP[value["status"]]
      elsif value["detail_type"] == "LocalOrder"
        order.state = Order::LOCAL_ORDER_STATUS_MAP[value["status"]]
      elsif
        order.state = value["status"].try(:downcase)
      end

      order.code = value["code"]
      order.detail_type = value["detail_type"]
      order.created_at = value["created_at"]
      order.updated_at = value["updated_at"] if value["updated_at"].present?
      order.people_helped = value["number_of_people_helped"]
      order.continuous = value["continuous"]
      order.shipment_date = value["sent_on"]
      order.staff_note = value["comments"]
      order.purpose_description = value["description"]

      ["process_completed_by_id", "cancelled_by_id", "closed_by_id", "dispatch_started_by_id",
        "submitted_by_id", "created_by_id"].each do |column_name|
        order.send("#{column_name}=", User.stockit_user.id)
      end
      order.save
    end
    Order.record_timestamps=true
    bar.finished
  end
end
