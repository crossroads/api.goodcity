require 'goodcity/cleanup'
require 'rails_helper'

context Goodcity::Cleanup do
  let(:dispatch_location) { create(:location, :dispatched) }

  subject { described_class.new }

  describe "Cleaning up dispatched packages_locations" do
    let(:packages_location) { create(:packages_location, location: dispatch_location, package: package) }
    let(:record_id) { packages_location.id }

    def run_cleanup
      Goodcity::Cleanup.delete_dispatched_packages_locations
    end

    context "when the package has a dispatched orders_packages" do
      let(:package) { create(:package) }

      before { create(:orders_package, :with_state_dispatched, package: package) }

      it "deletes the record" do
        expect { run_cleanup }.to change {
          PackagesLocation.find_by(id: record_id)
        }.from(packages_location).to(nil)
      end
    end

    context "when stockit_sent_on is set on the package" do
      let(:package) { create(:package, stockit_sent_on: Time.now) }

      it "deletes the record" do
        expect { run_cleanup }.to change {
          PackagesLocation.find_by(id: record_id)
        }.from(packages_location).to(nil)
      end
    end

    context "when the package isn't dispatched" do
      let(:package) { create(:package) }

      it "doesn't deletes the record" do
        expect { run_cleanup }.not_to change {
          PackagesLocation.find_by(id: record_id)
        }
      end
    end
  end
end