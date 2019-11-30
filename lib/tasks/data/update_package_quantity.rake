namespace :goodcity do
  namespace :data do

    # rake goodcity:data:update_package_quantity
    desc 'Fix negative package quantities'
    task update_package_quantity: :environment do
      file_path = File.join(Rails.application.root, "tmp", "update_package_quantity.csv")
      csv = CSV.open(file_path, "wb")
      csv << ["id", "inventory_number", "code", "action"]
      dry_run = (ENV['DRY_RUN'] == 'true')
      puts "Doing dry_run" if dry_run
      packages = Package.where("quantity < 0 AND stockit_sent_on IS NOT NULL")
      packages.find_each do |package|
        old_quantity = package.quantity
        package.quantity = 0
        csv << [package.id, package.inventory_number, package.designation_name, "Quantity was #{old_quantity}. Changing to 0."]
        package.save unless dry_run
      end
      csv.close
    end

  end
end