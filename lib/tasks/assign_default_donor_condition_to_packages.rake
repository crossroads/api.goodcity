require "goodcity/rake_logger"

namespace :goodcity do
  task assign_default_donor_condition: :environment do
    log = Goodcity::RakeLogger.new("assign_default_donor_condition")
    lightly_used_id = DonorCondition.find_by(name_en: 'Lightly Used').id

    count = 0

    begin
      Package.where('donor_condition_id is null and stockit_id is not null').find_each(batch_size: 100) do |package|
        package.donor_condition_id = lightly_used_id
        if package.save
          count += 1
        else
          log.error "Package save error: #{package.errors.full_messages}"
        end
      end
    rescue => e
      log.error "(#{e.message})"
    end

    log.info(": #{count} records updated")
    log.close
  end
end
