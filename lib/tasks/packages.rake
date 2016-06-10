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
end
