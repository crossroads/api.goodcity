namespace :stockit do

  desc 'Load designation details from Stockit'
  task add_designations: :environment do
    designations_json = Stockit::DesignationSync.index
    orders = JSON.parse(designations_json["designations"]) || []

    bar = RakeProgressbar.new(orders.size)
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

      order.status = value["status"]
      order.code = value["code"]
      order.detail_type = value["detail_type"]
      order.created_at = value["created_at"]
      order.description = value["description"]
      order.save
    end
    bar.finished
  end

end
