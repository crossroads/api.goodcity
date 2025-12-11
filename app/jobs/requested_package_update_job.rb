class RequestedPackageUpdateJob < ActiveJob::Base
  def perform(package_id)
    if (package = Package.find(package_id))
      package.requested_packages.each(&:update_availability!)
    end
  end
end
