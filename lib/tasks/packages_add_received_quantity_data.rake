require "goodcity/rake_logger"

# rake goodcity:packages_add_received_quantity_data
namespace :goodcity do
  desc 'Update packages with received_quantity'
  task packages_add_received_quantity_data: :environment do
    log = Goodcity::RakeLogger.new("packages_add_received_quantity_data")
    log.info("\n\tInitial Number of Packages =#{Package.count}")
    log.debug("\n\tInitial First Package(:id, :received_quantity, :quantity) before rake =#{Package.order(:id).limit(1).pluck(:id, :received_quantity, :quantity)}")
    log.debug("\n\tInitial Last Package(:id, :received_quantity, :quantity) before rake =#{Package.limit(1).pluck(:id, :received_quantity, :quantity)}")

    count = 0
    bar = RakeProgressbar.new(Package.count)
    Package.select("id, quantity, received_quantity, state").each do |package|
      bar.inc
      next if package.quantity == 0 and package.received_quantity != nil
      Package.connection.execute("UPDATE packages SET received_quantity = #{package.quantity} WHERE id = #{package.id}")
    end
    Package.where("order_id IS NOT NULL OR stockit_sent_on IS NOT NULL").update_all(quantity: 0)
    bar.finished

    log.info("\n\tUpdated Number of Packages affected=#{count}")
    log.debug("\n\tUpdated First Package(:id, :received_quantity, :quantity) after rake =#{Package.order(:id).limit(1).pluck(:id, :received_quantity, :quantity)}")
    log.debug("\n\tUpdated Last Package(:id, :received_quantity, :quantity) after rake =#{Package.limit(1).pluck(:id, :received_quantity, :quantity)}")
    log.close
  end
end
