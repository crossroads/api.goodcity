# rake goodcity:packages_add_received_quantity_data
namespace :goodcity do
  desc 'Update packages with received_quantity'
  task packages_add_received_quantity_data: :environment do
    # code to create log for the rake
    start_time = Time.now
    rake_logger = Logger.new("#{Rails.root}/log/rake_log.log")
    log = ("\n#{'-'*75}")
    rake_logger.info(log)
    log += ("\nRunning rake task 'packages_add_received_quantity_data'....")
    log += ("\nCurrent time: #{start_time}")
    log += ("\nInitial values")
    log += ("\n\tNumber of Packages =#{Package.count}")
    log += ("\n\tFirst Package(:id, :received_quantity, :quantity) before rake =#{Package.order(:id).limit(1).pluck(:id, :received_quantity, :quantity)}")
    log += ("\n\tLast Package(:id, :received_quantity, :quantity) before rake =#{Package.limit(1).pluck(:id, :received_quantity, :quantity)}")
    rake_logger.info(log)
    count = 0
    first_id = Package.first.id
    # end of code to create log for the rake
    Package.find_each(batch_size: 100) do |package|
      package.received_quantity = package.quantity
      package.quantity = 0 if (package.order_id || package.stockit_sent_on)
      if package.save
        count += 1
      else
        rake_logger.info("Update Failed for: #{package.id}")
      end
    end

    # code to create log for the rake
    end_time = Time.now
    log = ("\nTotal time taken: #{end_time-start_time} seconds")
    log += ("\nUpdated values")
    log += ("\n\tNumber of Packages affected=#{count}")
    log += ("\n\tFirst Package(:id, :received_quantity, :quantity) after rake =#{Package.order(:id).limit(1).pluck(:id, :received_quantity, :quantity)}")
    log += ("\n\tLast Package(:id, :received_quantity, :quantity) after rake =#{Package.limit(1).pluck(:id, :received_quantity, :quantity)}")
    rake_logger.info(log)
    rake_logger.close
    # end of code to create log for the rake
  end
end
