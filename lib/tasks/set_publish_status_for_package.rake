# to run this rake task run the following command.
# rake 'goodcity:set_publish_status_for_package[location_area, status]'
# rake 'goodcity:set_publish_status_for_package[xyz, true]'

namespace :goodcity do
  task :set_publish_status_for_package, %i[location_area status] => [:environment] do |task, args|
    location = Location.find_by(area: args.location_area)
    if location&.packages&.any?
      location.packages.update_all(allow_web_publish: true?(args.status))
      puts "#{location.packages.count} packages updated to allow_web_publish: #{args.status}"
    end
  end
end

def true?(status)
  status.downcase.casecmp("true").zero?
end
