#rake goodcity:change_allow_web_publish_to_false
namespace :goodcity do
  desc 'change allow_web_publish to false if package.quantity = 0'
  task change_allow_web_publish_to_false: :environment do
    packages = Package.where("quantity = ? and allow_web_publish = ?", 0, true)
    # code to create log for the rake
    start_time = Time.now
    rake_logger = Logger.new("#{Rails.root}/log/rake_log.log")
    log = ("\n#{'-'*75}")
    rake_logger.info(log)
    log += ("\nRunning rake task 'change_allow_web_publish_to_false'....")
    log += ("\nInitial values")
    log += ("\n\tNumber of Packages to be affected =#{packages.count}")
    log += ("\n\tallow_web_publish of 1st Package =#{packages.first.allow_web_publish}")
    log += ("\n\tallow_web_publish of last Package =#{packages.last.allow_web_publish}")
    rake_logger.info(log)
    count = 0
    # end of code to create log for the rake
    packages.find_each do |package|
      if package.update(allow_web_publish: false)
        count += 1
      else
        rake_logger.info("Update Failed for: #{package.id}")
      end
    end

    # code to create log for the rake
    end_time = Time.now
    log = ("\nTotal time taken: #{end_time-start_time} seconds")
    log += ("\nUpdated values")
    log += ("\n\tNumber of Packages affected =#{count}")
    log += ("\n\tallow_web_publish of 1st Package =#{packages.first.allow_web_publish}")
    log += ("\n\tallow_web_publish of last Package =#{packages.last.allow_web_publish}")
    rake_logger.info(log)
    rake_logger.close
    # end code to create log for the rake
  end
end
