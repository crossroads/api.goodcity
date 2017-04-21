namespace :goodcity do

  # rake goodcity:packages_add_received_quantity_data
  desc 'Update packages with received_quantity'
  task packages_add_received_quantity_data: :environment do
    # code to create log for the rake
    start_time = Time.now
    File.open("rake_log.txt", "a+"){|f|
      f << "\n#{'-'*80}"
      f << "\nRunning rake task 'packages_add_received_quantity_data'...."
      f << "\nCurrent time: #{x}"
      f << "\nInitial values"
      f << "\n\tNumber of Packages =#{Package.count}"
      f << "\n\tFirst Package(:id, :received_quantity, :quantity) before rake =#{Package.pluck(:id, :received_quantity, :quantity).first}"
      f << "\n\tLast Package(:id, :received_quantity, :quantity) before rake =#{Package.pluck(:id, :received_quantity, :quantity).last}"
    }
    first_id = PackagesLocation.last.id+1
    # end of code to create log for the rake
    Package.find_each(batch_size: 100) do |package|
      package.received_quantity = package.quantity
      package.quantity = 0 if (package.order_id || package.stockit_sent_on)
      package.save
    end

    # code to create log for the rake
    end_time = Time.now
    File.open("rake_log.txt", "a+"){|f|
      f << "\nTotal time taken: #{start_time-end_time} seconds"
      f << "\nUpdated values"
      f << "\n\tNumber of Packages =#{Package.count}"
      f << "\n\tFirst Package(:id, :received_quantity, :quantity) after rake =#{Package.where(id: first_id).pluck(:id, :received_quantity, :quantity).first}"
      f << "\n\tLast Package(:id, :received_quantity, :quantity) after rake =#{Package.pluck(:id, :received_quantity, :quantity).last}"
    }

    # end of code to create log for the rake
  end
end
