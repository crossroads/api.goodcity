require 'rails_helper'

RSpec.describe RequestedPackageUpdateJob, type: :job do

  context "when the package exists and has requested_packages" do
    let(:package) { create(:package, :in_user_cart) }
    let(:requested_packages) { package.requested_packages }
    it "finds the package and calls update_availability! on each requested package" do
      allow(Package).to receive(:find).with(package.id).and_return(package)
      allow(package).to receive(:requested_packages).and_return(requested_packages)
      requested_packages.each { |req| expect(req).to receive(:update_availability!) }
      RequestedPackageUpdateJob.new(package.id).perform_now
    end
  end

  context "when the package exists but has no requested_packages" do
    let(:package) { create(:package, requested_packages: []) }
    it "does not attempt to update anything" do
      package.requested_packages.destroy_all
      expect_any_instance_of(RequestedPackage).not_to receive(:update_availability!)
      RequestedPackageUpdateJob.new(package.id).perform_now
    end
  end

  context "when the package does not exist" do
    it "raises ActiveRecord::RecordNotFound" do
      allow(Package).to receive(:find).with(1).and_raise(ActiveRecord::RecordNotFound)
      expect { RequestedPackageUpdateJob.new(1).perform_now }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end