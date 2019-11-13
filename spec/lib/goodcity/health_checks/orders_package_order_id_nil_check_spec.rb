require 'rails_helper' # needed to configure transaction rollback
require 'goodcity/health_checks'

context Goodcity::HealthChecks::OrdersPackageOrderIdCheck do

  subject { described_class.new }

  it { expect(subject.class.desc).to eql("OrdersPackages should contain an order_id reference.") }

  it "passes" do
    WebMock.disable!
    order = create :order
    package = create :package, :received
    create :orders_package, order: order, package: package
    subject.run
    expect(subject.passed?).to eql(true)
    WebMock.enable!
  end

  # it "fails" do
  #   orders_package = build :orders_package, order_id: nil
  #   expect(orders_package.valid?).to eql(false)
  #   expect(orders_package.errors.messages).to eql({:order=>["can't be blank"]})
  # end

end
