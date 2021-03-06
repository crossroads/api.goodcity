require 'rails_helper' # needed to configure transaction rollback
require 'goodcity/health_checks'

context Goodcity::HealthChecks::PackageDispatchedOrderIdNilCheck do

  subject { described_class.new }

  let(:order) { create :order }

  it { expect(subject.class.desc).to eql("Dispatched packages should contain an order_id reference.") }

  context "passes" do
    it "with stockit_sent_on" do
      create :package, stockit_sent_on: Date.today, order_id: order.id
      subject.run
      expect(subject.passed?).to eql(true)
    end
    it "with nil stockit_sent_on" do
      create :package, stockit_sent_on: nil, order_id: order.id
      subject.run
      expect(subject.passed?).to eql(true)
    end
  end

  context "fails" do
    it "with nil order_id" do
      create(:package, stockit_sent_on: Date.today, order_id: nil)
      subject.run
      expect(subject.passed?).to eql(false)
      expect(subject.message).to include("GoodCity Dispatched Packages with nil sent_on and order_id")
    end
  end

end
