require 'rails_helper' # needed to configure transaction rollback
require 'goodcity/health_checks'

context Goodcity::HealthChecks::OrdersPackageOrderIdCheck do

  before do
    allow(Stockit::OrdersPackageSync).to receive(:create)
    allow(Stockit::OrdersPackageSync).to receive(:update)
    User.current_user = create(:user)
  end

  subject { described_class.new }
  let!(:orders_package) { create(:orders_package) }

  it { expect(subject.class.desc).to eql("OrdersPackages should contain an order_id reference.") }

  it "passes" do
    subject.run
    expect(subject.passed?).to eql(true)
  end

  it "fails" do
    orders_package.update_column(:order_id, nil)
    expect(subject.passed?).to eql(false)
  end

end
