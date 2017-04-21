#rake goodcity:change_allow_web_publish_to_false

namespace :goodcity do
  desc 'change allow_web_publish to false if package.quantity = 0'
  task change_allow_web_publish_to_false: :environment do
    packages = Package.where("quantity = ? and allow_web_publish = ?", 0, true)

    # code to create log for the rake
    start_time = Time.now
    File.open("rake_log.txt", "a+"){|f|
      f << "\n#{'-'*80}"
      f << "\nRunning rake task 'change_allow_web_publish_to_false'...."
      f << "\nCurrent time: #{x}"
      f << "\nInitial values"
      f << "\n\tNumber of Packages to be affected =#{packages.count}"
      f << "\n\tallow_web_publish of 1st Package =#{packages.first.allow_web_publish}"
      f << "\n\tallow_web_publish of last Package =#{packages.last.allow_web_publish}"
    }
    # end of code to create log for the rake

    packages.find_each do |package|
      package.update(allow_web_publish: false)
    end

    # code to create log for the rake
    end_time =Time.now
    File.open("rake_log.txt", "a+"){|f|
      f << "\nTotal time taken: #{start_time-end_time} seconds"
      f << "\nUpdated values"
      f << "\n\tNumber of Packages affected =#{packages.count}"
      f << "\n\tallow_web_publish of 1st Package =#{packages.first.allow_web_publish}"
      f << "\n\tallow_web_publish of last Package =#{packages.last.allow_web_publish}"
    }
    # end code to create log for the rake
  end
end
