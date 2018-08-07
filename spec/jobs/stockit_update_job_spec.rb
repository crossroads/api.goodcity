require "rails_helper"

describe StockitUpdateJob, :type => :job do

  let(:package) { create(:package, :stockit_package) }
  let(:err) { {"errors" => {:connection_error => "Error"}} }

  subject { StockitUpdateJob.new }

  it "should update the item in Stockit" do
    expect(Stockit::ItemSync).to receive(:update).with(package, package.request_from_admin)
    subject.perform(package.id)
  end

  it "should ignore packages that don't exist" do
    expect(Stockit::ItemSync).not_to receive(:update)
    subject.perform("1")
  end

  it "should log error messages" do
    expect(Stockit::ItemSync).to receive(:update).with(package, package.request_from_admin).and_return(err)
    err_msg = "Inventory: #{package.inventory_number} Package: #{package.id} connection_error: Error"
    expect(subject).to receive_message_chain(:logger, :error).with(err_msg)
    subject.perform(package.id)
  end

end
