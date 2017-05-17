namespace :stockit do

  desc 'Load local_order details from Stockit'
  task add_stockit_local_orders: :environment do
    local_orders_json = Stockit::LocalOrderSync.index
    stockit_local_orders = JSON.parse(local_orders_json["local_orders"]) || []
    bar = RakeProgressbar.new(stockit_local_orders.size)
    stockit_local_orders.each do |value|
      bar.inc
      local_order = StockitLocalOrder.where(stockit_id: value["id"]).first_or_initialize
      local_order.client_name = value["client_name"]
      local_order.hkid_number = value["hkid_number"]
      local_order.reference_number = value["reference_number"]
      local_order.purpose_of_goods = value["purpose_of_goods"]
      local_order.save
    end
    bar.finished
  end

end
