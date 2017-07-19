require 'rails_helper' # needed to configure transaction rollback
require 'goodcity/health_checks/orders_packages_order_id_check'

context Goodcity::HealthChecks::OrdersPackagesOrderIdCheck do

  subject { described_class.new }

  it { expect(subject.desc).to eql("OrdersPackages should contain an order_id reference.") }

  it "passes" do
    create :orders_package, order_id: 123, package_id: 111
    subject.run
    expect(subject.passed?).to eql(true)
  end

  it "fails" do
    orders_package = build :orders_package, order_id: nil
    expect(orders_package.valid?).to eql(false)
    expect(orders_package.errors.messages).to eql({:order=>["can't be blank"]})
  end

end
