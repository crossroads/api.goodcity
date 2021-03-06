require 'goodcity/package_setup'

namespace :goodcity do

  # rake goodcity:update_packages_grade_condition
  desc 'Update package with grade and donor_condition_id'
  task update_packages_grade_condition: :environment do
    Package.find_in_batches(batch_size: 50).each do |packages|
      packages.each do |package|
        # using update_column to not sync with stockit for now,
        # as it might update existing data in stockit.
        package.update_column(:grade, "B")
        package.update_column(:donor_condition_id, package.item.donor_condition_id)
        puts "Updated package: #{package.id}"
      end
    end

  end

  # rake goodcity:update_package_image
  desc 'Update package with favourite_image'
  task update_package_image: :environment do
    Package.find_in_batches(batch_size: 100).each do |packages|
      packages.each do |package|
        if(package.item)
          image = package.item.images.find_by(favourite: true)
          package.update_column(:favourite_image_id, image.try(:id))
          puts "Updated package: #{package.id}"
        end
      end
    end

  end

  # rake goodcity:update_salable_for_offers_and_packages
  desc 'update_salable_for_offers_and_packages'
  task update_salable_for_offers_and_packages: :environment do
    puts "Updated Offer--START"
    Offer.with_deleted.find_in_batches(batch_size: 100).each do |offers|
      offers.each do |offer|
        saleable_value = offer.items.first.try(:saleable)
        if saleable_value
          offer.update_column(:saleable, saleable_value)
          Package.where(offer_id: offer.id).update_all(saleable: saleable_value)
          puts "Offer-#{offer.id}"
        end
      end
    end
    puts "Updated Offer--END"
  end

  # rake goodcity:update_set_item_id_for_packages
  desc "update set_item_id for packages"
  task update_set_item_id_for_packages: :environment do
    Item.find_in_batches(batch_size: 100).each do |items|
      items.each do |item|
        packages = item.packages.inventorized.non_set_items
        if packages.length > 1
          packages.update_all(set_item_id: item.id)
        end
      end
    end
  end

  # rake goodcity:update_package_favourite_image
  desc "update favourite_image of packages"
  task update_package_favourite_image: :environment do
    Item.find_in_batches(batch_size: 100).each do |items|
      items.each do |item|
        item.packages.each do |package|
          image =
            if package.favourite_image_id
              Image.find_by(id: package.favourite_image_id)
            else
              item.images.where(favourite: true).first
            end
          if image
            package.images.create(
              cloudinary_id: image.cloudinary_id,
              favourite: true,
              angle: image.angle)
          end
        end
      end
    end
  end

  # Base usage:
  #   > rake goodcity:compute_quantities
  #
  # Rehearsal
  #   > rake goodcity:compute_quantities[rehearse]
  #
  #   Rehearsal will not apply any changes to the packages
  #
  desc "Compute the quantity fields of all packages"
  task :compute_quantities, [:param] => [:environment] do |_, args|
    Goodcity::PackageSetup.compute_quantities(rehearse: args[:param].eql?('rehearse'))
  end

  # rails goodcity:set_offer_for_packages
  desc "update offers for packages"
  task set_offer_for_packages: :environment do
    item_packages = Package.inventorized.received.where.not(item_id: nil)
    item_packages.find_in_batches(batch_size: 100).each do |packages|
      packages.each do |package|
        package.assign_offer unless package.offers_packages.map(&:offer_id).include?(package.item.offer_id)
      end
    end
  end

  # rails goodcity:update_package_value_hk_dollar
  desc "update value_hk_dollar of packages"
  task update_package_value_hk_dollar: :environment do
    Package
      .where(value_hk_dollar: nil)
      .find_in_batches(batch_size: 100).each do |packages|
        packages.each do |package|
          hk_value = ValuationCalculationHelper.new(
            package.donor_condition_id,
            package.grade,
            package.package_type_id
          ).calculate

          package.update_column(:value_hk_dollar, hk_value)
        end
    end
  end
end
