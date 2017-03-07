namespace :stockit do

  desc 'Load designation details from Stockit'
  task add_designations: :environment do

    designations_json = Stockit::DesignationSync.index
    orders = JSON.parse(designations_json["designations"])

    if orders
      orders.each do |value|
        designation = Order.where(stockit_id: value["id"]).first_or_create

        detail_id = if (value["detail_type"] === "LocalOrder") && value["detail_id"].present?
          StockitLocalOrder.find_by(stockit_id: value["detail_id"]).try(:id)
        else
          value["detail_id"]
        end

        activity_id = if value["activity_id"].present?
          StockitActivity.find_by(stockit_id: value["activity_id"]).try(:id)
        end

        contact_id = if value["contact_id"].present?
          StockitContact.find_by(stockit_id: value["contact_id"]).try(:id)
        end

        organisation_id = if value["organisation_id"].present?
          StockitOrganisation.find_by(stockit_id: value["organisation_id"]).try(:id)
        end

        country_id = if value["country_id"].present?
          Country.find_by(stockit_id: value["country_id"]).try(:id)
        end

        designation.update(
          status: value["status"],
          code: value["code"],
          detail_type: value["detail_type"],
          created_at: value["created_at"],
          description: value["description"],

          stockit_activity_id: activity_id,
          stockit_contact_id: contact_id,
          stockit_organisation_id: organisation_id,
          country_id: country_id,
          detail_id: detail_id
        )

        puts "Updated designation #{designation.id}"
      end
    end
  end
end
