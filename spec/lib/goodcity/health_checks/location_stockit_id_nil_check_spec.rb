require 'rails_helper' # needed to configure transaction rollback
require 'goodcity/health_checks'

context Goodcity::HealthChecks::LocationStockitIdNilCheck do

  subject { described_class.new }

  it { expect(subject.class.desc).to eql("Locations should contain a stockit_id reference.") }

  it "passes" do
    FactoryBot.create :location, stockit_id: 123
    subject.run
    expect(subject.passed?).to eql(true)
  end

  it "fails" do
    FactoryBot.create :location, stockit_id: nil
    subject.run
    expect(subject.passed?).to eql(false)
    expect(subject.message).to include("GoodCity Locations with nil stockit_id")
  end

end