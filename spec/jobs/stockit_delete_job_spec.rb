require "rails_helper"

describe StockitDeleteJob, :type => :job do

  let(:package) { create(:package, :stockit_package) }
  let(:err) { {"errors" => {:connection_error => "Error"}} }

  subject { StockitDeleteJob.new }

  it "should delete the item in Stockit" do
    expect(Stockit::Item).to receive(:delete).with(package)
    subject.perform(package.id)
  end

  it "should ignore packages that don't exist" do
    expect(Stockit::Item).not_to receive(:delete)
    subject.perform("1")
  end

  it "should log error messages" do
    expect(Stockit::Item).to receive(:delete).with(package).and_return(err)
    err_msg = "Inventory: #{package.inventory_number} connection_error: Error"
    expect(subject).to receive_message_chain(:logger, :error).with(err_msg)
    subject.perform(package.id)
  end

end
