namespace :goodcity do

  # rake goodcity:update_packages
  desc 'Update package with grade and donor_condition_id'
  task update_packages: :environment do

    Package.find_in_batches(batch_size: 50).each do |packages|
      packages.each do |package|
        # using update_column to not sync with stokit for now,
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
        packages = item.packages.inventorized
        if packages.length > 1
          packages.update_all(set_item_id: item.id)
        end
      end
    end
  end
end
