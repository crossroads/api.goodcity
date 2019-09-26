# rake stockit:sync_subform_to_gc_pkg_types

namespace :stockit do
  task sync_subform_to_gc_pkg_types: :environment do
    log = Goodcity::RakeLogger.new("sync_subform_to_gc_pkg_types")
    codes_json = Stockit::CodeSync.index # fetch stockit codes
    return if codes_json.blank? || codes_json.nil?
    stockit_codes = JSON.parse(codes_json["codes"])
    bar = RakeProgressbar.new(stockit_codes.size)
    update_package_type_ids = []

    if codes_json["errors"]
      log.info("Errors: #{codes_json[errors]}")
      puts codes_json["errors"] && return
    end

    stockit_codes.each do |code|
      next if code["subform"].nil? || code["id"].nil?
      package_type = PackageType.find_by(stockit_id: code["id"])
      next if package_type.nil?
      update_package_type_ids << package_type.id if package_type.update_column(:subform, code["subform"])
      bar.inc
    end
    bar.finished
    log.info("updated package_type ids: #{update_package_type_ids}")
    log.info("#{update_package_type_ids.size} package_types updated.")
  end
end
