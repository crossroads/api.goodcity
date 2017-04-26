require "goodcity/rake_logger"
#rake goodcity:change_allow_web_publish_to_false
namespace :goodcity do
  desc 'change allow_web_publish to false if package.quantity = 0'
  task change_allow_web_publish_to_false: :environment do
    packages = Package.where("quantity = ? and allow_web_publish = ?", 0, true)
    # code to create log for the rake
    log = Goodcity::RakeLogger.new("change_allow_web_publish_to_false")
    log.info("\n\tInitial Number of Packages to be affected =#{packages.count}")
    log.debug("\n\tInitial allow_web_publish of 1st Package =#{packages.first.allow_web_publish}")
    log.debug("\n\tInitial allow_web_publish of last Package =#{packages.last.allow_web_publish}")
    count = 0
    # end of code to create log for the rake
    packages.find_each do |package|
      if package.update(allow_web_publish: false)
        count += 1
      else
        log.error("Update Failed for: #{package.id}")
      end
    end

    # code to create log for the rake
    log.info("\n\tUpdated Number of Packages affected =#{count}")
    log.debug("\n\tUpdated allow_web_publish of 1st Package =#{packages.first.allow_web_publish}")
    log.debug("\n\tUpdated allow_web_publish of last Package =#{packages.last.allow_web_publish}")
    log.close
    # end code to create log for the rake
  end
end
