require "goodcity/rake_logger"

namespace :goodcity do
  task assign_default_donor_condition: :environment do
    log = Goodcity::RakeLogger.new("assign_default_donor_condition")
    lightly_used = DonorCondition.find_by(name_en: 'Lightly Used')

    nil_donor_condition_count = Package.where(donor_condition_id: nil).count
    log.info(": #{nil_donor_condition_count} records has nil donor_condition")

    count = 0

    begin
      Package.where(donor_condition_id: nil).find_each(batch_size: 50) do |package|
        package.donor_condition_id = lightly_used.id
        count += 1 if package.save
      end
    rescue => e
      log.error "(#{e.message})"
    end

    log.info(": #{count} records updated")
    log.close
  end
end
