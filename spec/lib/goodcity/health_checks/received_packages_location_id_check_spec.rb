require 'rails_helper' # needed to configure transaction rollback
require 'goodcity/health_checks/received_packages_location_id_check'

context Goodcity::HealthChecks::ReceivedPackagesLocationIdCheck do

  subject { described_class.new }

  let(:location) { create :location }

  it { expect(subject.desc).to eql("Received Packages should contain location_id reference.") }

  it "passes" do
    create :package, location_id: location.id, inventory_number: "000001"
    subject.run
    expect(subject.passed?).to eql(true)
  end

  it "fails" do
    create :package, location_id: nil, inventory_number: "000001"
    subject.run
    expect(subject.passed?).to eql(false)
    expect(subject.message).to include("GoodCity received Packages with nil location_id")
  end

end
