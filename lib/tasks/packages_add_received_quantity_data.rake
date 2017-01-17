namespace :goodcity do

  # rake goodcity:packages_add_received_quantity_data
  desc 'Update packaes with received_quantity'
  task packages_add_received_quantity_data: :environment do
    Package.find_each(batch_size: 100) do |package|
      package.received_quantity = package.quantity
      package.quantity = 0 if (package.order_id || package.stockit_sent_on)
      package.save
    end
  end
end
