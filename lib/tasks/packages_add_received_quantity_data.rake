require "goodcity/rake_logger"
# rake goodcity:packages_add_received_quantity_data
namespace :goodcity do
  desc 'Update packages with received_quantity'
  task packages_add_received_quantity_data: :environment do
    # code to create log for the rake
    log = Goodcity::RakeLogger.new("packages_add_received_quantity_data")
    log.log_info("\nRunning rake task 'packages_add_received_quantity_data'....")
    log.log_info("\nInitial values")
    log.log_info("\n\tNumber of Packages =#{Package.count}")
    log.log_info("\n\tFirst Package(:id, :received_quantity, :quantity) before rake =#{Package.order(:id).limit(1).pluck(:id, :received_quantity, :quantity)}")
    log.log_info("\n\tLast Package(:id, :received_quantity, :quantity) before rake =#{Package.limit(1).pluck(:id, :received_quantity, :quantity)}")
    count = 0
    first_id = Package.first.id
    # end of code to create log for the rake
    Package.find_each(batch_size: 100) do |package|
      package.received_quantity = package.quantity
      package.quantity = 0 if (package.order_id || package.stockit_sent_on)
      if package.save
        count += 1
      else
        log.log_info("Update Failed for: #{package.id}")
      end
    end

    # code to create log for the rake
    log.log_info("\nUpdated values")
    log.log_info("\n\tNumber of Packages affected=#{count}")
    log.log_info("\n\tFirst Package(:id, :received_quantity, :quantity) after rake =#{Package.order(:id).limit(1).pluck(:id, :received_quantity, :quantity)}")
    log.log_info("\n\tLast Package(:id, :received_quantity, :quantity) after rake =#{Package.limit(1).pluck(:id, :received_quantity, :quantity)}")
    log.close
    # end of code to create log for the rake
  end
end
