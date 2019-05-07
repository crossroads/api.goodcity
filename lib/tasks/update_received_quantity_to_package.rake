# rake goodcity:update_received_quantity_to_package
require 'goodcity/update_package_received_quantity'

namespace :goodcity do
  desc 'Update received quantities to package'
  task update_received_quantity_to_package: :environment do
    GoodCity::UpdatePackageReceivedQuantity.run!
  end
end
