class StockitUpdateJob < ActiveJob::Base
  queue_as :stockit_updates

  def perform(package_id)
    package = Package.find_by(id: package_id)

    if package
      response = Stockit::Browse.new(package).update_item

      if response && (errors = response["errors"] || response[:errors])
        Stockit::Browse.log_errors("StockitUpdateJob", errors, package.inventory_number, package)
      end
    end
  end
end
