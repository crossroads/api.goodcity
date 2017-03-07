namespace :stockit do

  desc 'Load local_order details from Stockit'
  task add_stockit_local_orders: :environment do
    # StockitLocalOrder.delete_all

    local_orders_json = Stockit::LocalOrderSync.index
    stockit_local_orders = JSON.parse(local_orders_json["local_orders"])

    if stockit_local_orders
      stockit_local_orders.each do |value|
        local_order = StockitLocalOrder.where(
          stockit_id: value["id"],
          client_name: value["client_name"],
          hkid_number: value["hkid_number"],
          reference_number: value["reference_number"],
          purpose_of_goods: value["purpose_of_goods"]
        ).first_or_create
      end
    end
  end
end
