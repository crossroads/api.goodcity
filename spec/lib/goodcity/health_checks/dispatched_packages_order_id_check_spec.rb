require 'rails_helper' # needed to configure transaction rollback
require 'goodcity/health_checks/dispatched_packages_order_id_check'

context Goodcity::HealthChecks::DispatchedPackagesOrderIdCheck do

  subject { described_class.new }

  let(:order) { create :order }

  it { expect(subject.desc).to eql("Dispatched packages should contain an order_id reference.") }

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
      create :package, stockit_sent_on: Date.today, order_id: nil
      subject.run
      expect(subject.passed?).to eql(false)
      expect(subject.message).to include("GoodCity Dispatched Packages with nil sent_on or order_id")
    end
  end

end
