require "goodcity/rake_logger"
#rake goodcity:change_allow_web_publish_to_false
namespace :goodcity do
  desc 'change allow_web_publish to false if package.quantity = 0'
  task change_allow_web_publish_to_false: :environment do
    packages = Package.where("quantity = ? and allow_web_publish = ?", 0, true)
    # code to create log for the rake
    log = Goodcity::RakeLogger.new("change_allow_web_publish_to_false")
    log.log_info("\n#{'-'*75}")
    log.log_info("\nRunning rake task 'change_allow_web_publish_to_false'....")
    log.log_info("\nInitial values")
    log.log_info("\n\tNumber of Packages to be affected =#{packages.count}")
    log.log_info("\n\tallow_web_publish of 1st Package =#{packages.first.allow_web_publish}")
    log.log_info("\n\tallow_web_publish of last Package =#{packages.last.allow_web_publish}")
    count = 0
    # end of code to create log for the rake
    packages.find_each do |package|
      if package.update(allow_web_publish: false)
        count += 1
      else
        log.log_info("Update Failed for: #{package.id}")
      end
    end

    # code to create log for the rake
    log.log_info("\nUpdated values")
    log.log_info("\n\tNumber of Packages affected =#{count}")
    log.log_info("\n\tallow_web_publish of 1st Package =#{packages.first.allow_web_publish}")
    log.log_info("\n\tallow_web_publish of last Package =#{packages.last.allow_web_publish}")
    log.close
    # end code to create log for the rake
  end
end
