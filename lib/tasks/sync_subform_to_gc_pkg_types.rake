# rake stockit:sync_subform_to_gc_pkg_types

namespace :stockit do
  task sync_subform_to_gc_pkg_types: :environment do
    log = Goodcity::RakeLogger.new("sync_subform_to_gc_pkg_types")
    codes_json = Stockit::CodeSync.index # fetch stockit codes
    stockit_codes = JSON.parse(codes_json["codes"])
    bar = RakeProgressbar.new(stockit_codes.size)
    count = 0
    update_package_type_ids = []

    if codes_json["errors"]
      log.info("Errors: #{codes_json[errors]}")
      puts codes_json["errors"]
    end

    stockit_codes.each do |code|
      bar.inc
      package_type = PackageType.find_by(stockit_id: code["id"]) if code["id"]
      next if code["subform"].nil? || package_type.nil?
      if package_type
        count+= 1
        package_type.update_column(:subform, code["subform"])
        update_package_type_ids << package_type.id
      end
    end
    bar.finished
    log.info("updated packageType ids: #{update_package_type_ids}")
    log.info("#{count} package_types updated.")
    puts "#{count} package_types updated."
    puts "updated packageType ids: #{update_package_type_ids}"
  end
end
