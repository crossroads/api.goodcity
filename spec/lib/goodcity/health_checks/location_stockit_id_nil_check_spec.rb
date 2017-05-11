require 'rails_helper' # needed to configure transaction rollback
require 'goodcity/health_checks/location_stockit_id_nil_check'

context Goodcity::HealthChecks::LocationStockitIdNilCheck do

  subject { described_class.new }

  it { expect(subject.desc).to eql("Locations should contain a stockit_id reference.") }

  it "passes" do
    FactoryGirl.create :location, stockit_id: 123
    subject.run
    expect(subject.passed?).to eql(true)
  end

  it "fails" do
    FactoryGirl.create :location, stockit_id: nil
    subject.run
    expect(subject.passed?).to eql(false)
    expect(subject.message).to include("GoodCity Locations with nil stockit_id")
  end

end