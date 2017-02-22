require "rails_helper"

describe StockitSyncOrdersPackageJob, :type => :job do

  let(:inventory_number) { "H12345" }
  let(:package) { create :package, :stockit_package }
  let(:orders_package) { create :orders_package }
  let(:err) { {"errors" => {:connection_error => "Error"}} }

  subject { StockitSyncOrdersPackageJob.new }

  it 'creates orders_package in stockit if create operation' do
    expect(Stockit::OrdersPackageSync).to receive(:create).with(package, orders_package)
    subject.perform(package.id, orders_package.id, "create")
  end

  it 'updates orders_package in stockit if update operation' do
    expect(Stockit::OrdersPackageSync).to receive(:update).with(package, orders_package)
    subject.perform(package.id, orders_package.id, "update")
  end

  it 'deletes orders_package in stockit if delete operation' do
    expect(Stockit::OrdersPackageSync).to receive(:delete).with(package, orders_package)
    subject.perform(package.id, orders_package.id, "destroy")
  end

  it "logs error messages" do
    expect(Stockit::OrdersPackageSync).to receive(:delete).with(package, orders_package).and_return(err)
    err_msg = "Inventory: #{package.inventory_number} Package: #{package.id} connection_error: Error"
    expect(subject).to receive_message_chain(:logger, :error).with(err_msg)
    subject.perform(package.id, orders_package.id, "destroy")
  end
end
