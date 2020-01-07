# rake orders:map_shipment_status
namespace :orders do
  desc 'Map Stockit Shipment status to Order state'
  task map_shipment_status: :environment do
    Order::SHIPMENT_STATUS_MAP.each do |status, state|
      # pure sql, no callbacks
      Order.shipments.where(status: status).update_all(state: state)
    end
  end
end
