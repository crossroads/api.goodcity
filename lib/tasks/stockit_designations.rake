namespace :goodcity do

  # rake goodcity:add_stockit_designations
  desc 'Load designation details from stockit'
  task add_stockit_designations: :environment do
    StockitDesignation.delete_all

    designations_json = Stockit::DesignationSync.index
    stockit_designations = JSON.parse(designations_json["designations"])

    if stockit_designations
      stockit_designations.each do |value|
        designation = StockitDesignation.where(
          status: value["status"],
          code: value["code"],
          detail_type: "StockitLocalOrder",
          stockit_id: value["id"],
          created_at: value["created_at"],
          description: value["description"],

          stockit_activity_id: StockitActivity.find_by(stockit_id: value["activity_id"]).try(:id),
          stockit_contact_id: StockitContact.find_by(stockit_id: value["contact_id"]).try(:id),
          stockit_organisation_id: StockitOrganisation.find_by(stockit_id: value["organisation_id"]).try(:id),
          detail_id: StockitLocalOrder.find_by(stockit_id: value["detail_id"]).try(:id)

        ).first_or_create
      end
    end
  end
end
